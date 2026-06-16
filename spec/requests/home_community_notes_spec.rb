require "rails_helper"

# Public notes on the homepage appear in the community section only.
RSpec.describe "Homepage community notes", type: :request do
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

  describe "GET / with no public notes" do
    it "renders the hero without a community section" do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("home.welcome"))
      expect(response.body).not_to include('id="community"')
    end
  end

  describe "GET / with public notes" do
    it "lists public notes in the community section" do
      note = create(:note, user: author, body: "<p>The hinge of the gospel.</p>", visibility: :public_note)
      highlight = create(:highlight, user: author, translation: translation,
                                     osis_ref: "Bible.KJV.John.3.16!4-Bible.KJV.John.3.16!7",
                                     color: "gold")
      create(:highlight_note, highlight: highlight, note: note)

      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="community"')
      expect(response.body).to include("Apollos")
      expect(response.body).to include("hinge of the gospel")
      expect(response.body).not_to include("landing-hero-grid")
    end

    it "skips a hidden public note" do
      note = create(:note, user: author, body: "<p>Hidden thought.</p>", visibility: :public_note,
                           hidden_at: Time.current)
      highlight = create(:highlight, user: author, translation: translation,
                                     osis_ref: "Bible.KJV.John.3.16!4-Bible.KJV.John.3.16!7",
                                     color: "gold")
      create(:highlight_note, highlight: highlight, note: note)

      get "/"
      expect(response.body).not_to include("Hidden thought")
    end

    it "includes featured notes in the community list" do
      note = create(:note, user: author,
                        body: "<p>The hinge of the gospel.</p>",
                        visibility: :public_note,
                        featured: true,
                        featured_at: 1.minute.ago)
      hl = create(:highlight, user: author, translation: translation,
                              osis_ref: "Bible.KJV.John.3.16!4-Bible.KJV.John.3.16!7",
                              color: "gold")
      create(:highlight_note, highlight: hl, note: note)

      get "/"
      expect(response.body).to include("Apollos")
      expect(response.body).to include("hinge of the gospel")
      expect(response.body).to include('href="/public/bible/kjv/john/3"')
    end
  end
end
