require "rails_helper"

RSpec.describe "Public::Bible", type: :request do
  let!(:translation) { create(:translation, :kjv) }
  let!(:book)        { create(:book, :john, translation: translation) }
  let!(:chapter)     { create(:chapter, book: book, number: 3) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.John.3.16")
  end
  let(:author) { create(:user, display_name: "Apollos") }

  def public_note!(body:, featured: false)
    # Each note gets its own author (and thus its own highlight —
    # Highlight uniqueness is scoped to user_id/osis_ref/color).
    user = create(:user)
    highlight = create(:highlight, user: user, translation: translation,
                                   osis_ref: "Bible.KJV.John.3.16", color: "gold")
    note = create(:note, user: user, body: "<p>#{body}</p>",
                         visibility: :public_note, featured: featured,
                         featured_at: (featured ? Time.current : nil))
    create(:highlight_note, highlight: highlight, note: note)
    note
  end

  describe "the community layer at /bible (Sprint R7 merge)" do
    it "301-redirects the old /public/bible URLs into the reader's community layer" do
      get "/public/bible/kjv/john/3"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/bible/kjv/john/3?layer=community")
    end

    it "301-redirects case-mismatched /public/bible paths to the lowercase community layer" do
      get "/public/bible/KJV/John/3"
      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/bible/kjv/john/3?layer=community")
    end

    it "serves the community layer to anonymous visitors at /bible directly" do
      public_note!(body: "Community thought")
      get "/bible/kjv/john/3"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("For God so loved the world")
      expect(response.body).to include("Community thought")
    end

    it "serves the community layer to signed-in users with ?layer=community" do
      public_note!(body: "Community thought")
      sign_in create(:user)
      get "/bible/kjv/john/3", params: { layer: "community" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Community thought")
    end

    it "renders community highlights as dotted underlines, never fills" do
      public_note!(body: "Community thought")
      get "/bible/kjv/john/3"
      # Design v3 / Kindle rule: other people's highlights are a quiet
      # dotted underline; color fills are reserved for your own marks.
      expect(response.body).to include("community-highlight")
      expect(response.body).not_to match(/class="[^"]*highlight-(yellow|green|blue|rose|gold|sage|lavender|sky)/)
    end

    it "labels community underlines with how many people highlighted the verse" do
      public_note!(body: "First voice")
      second = create(:user)
      highlight = create(:highlight, user: second, translation: translation,
                                     osis_ref: "Bible.KJV.John.3.16", color: "blue")
      note = create(:note, user: second, body: "<p>Second voice</p>", visibility: :public_note)
      create(:highlight_note, highlight: highlight, note: note)

      get "/bible/kjv/john/3"

      expect(response.body).to include(I18n.t("public_bible.people_highlighted", count: 2))
      expect(response.body).to include('aria-label="' + I18n.t("public_bible.people_highlighted", count: 2) + '"')
    end

    it "excludes hidden notes from anonymous view" do
      hidden = public_note!(body: "Bad content")
      hidden.update!(hidden_at: Time.current)
      get "/bible/kjv/john/3"
      expect(response.body).not_to include("Bad content")
    end

    it "includes hidden notes when viewed by an admin" do
      hidden = public_note!(body: "Under review")
      hidden.update!(hidden_at: Time.current)
      admin = create(:user, admin: true)
      sign_in admin
      get "/bible/kjv/john/3", params: { layer: "community" }
      expect(response.body).to include("Under review")
    end

    it "404s on unknown translations" do
      get "/bible/xyz/john/3"
      expect(response).to have_http_status(:not_found)
    end

    it "orders notes: featured first, then popular, then newest" do
      plain_old = public_note!(body: "OLD PLAIN")
      plain_old.update!(created_at: 2.days.ago)
      popular = public_note!(body: "POPULAR")
      2.times { create(:upvote, note: popular) }
      pinned = public_note!(body: "PINNED", featured: true)

      get "/bible/kjv/john/3"
      body = response.body
      expect(body.index("PINNED")).to be < body.index("POPULAR")
      expect(body.index("POPULAR")).to be < body.index("OLD PLAIN")
    end
  end

  describe "translation picker on the community layer" do
    it "is not rendered when only one translation is installed" do
      get "/bible/kjv/john/3"
      expect(response.body).not_to include(%(aria-label="Translation"))
    end

    it "renders the picker when two translations are installed, with options pointing at the same chapter in each translation and the current one marked selected" do
      rv1909 = create(:translation, code: "RV1909", name: "Reina-Valera 1909", language: "es")
      rv_book = create(:book, :john, translation: rv1909)
      rv_chapter = create(:chapter, book: rv_book, number: 3)
      create(:verse, chapter: rv_chapter, number: 16,
                     body_text: "Porque de tal manera amó Dios al mundo",
                     body_html: "Porque de tal manera amó Dios al mundo",
                     red_letter_ranges: [],
                     osis_ref: "Bible.RV1909.John.3.16")

      get "/bible/kjv/john/3"
      expect(response.body).to include(%(aria-label="Translation"))
      expect(response.body).to include(%(data-url="/bible/kjv/john/3?layer=community"))
      expect(response.body).to include(%(data-url="/bible/rv1909/john/3?layer=community"))
      expect(response.body).to match(%r{<button[^>]*data-url="/bible/kjv/john/3\?layer=community"[^>]*aria-selected="true"}m)
    end
  end

  describe "GET / (root) for signed-out users" do
    it "renders the home page with a Read the Bible CTA" do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/public/bible/kjv/gen/1")
    end
  end
end
