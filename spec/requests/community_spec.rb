require "rails_helper"

RSpec.describe "Community feed", type: :request do
  let(:translation) { create(:translation, :kjv) }
  let(:book) { create(:book, :john, translation: translation) }
  let(:chapter) { create(:chapter, book: book, number: 3) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   osis_ref: "Bible.KJV.John.3.16")
  end
  let(:author) { create(:user, display_name: "Apollos") }

  # Each call gets a unique character range so the (user, osis_ref,
  # color) uniqueness on highlights never collides across notes.
  def public_note!(body:, osis_ref: nil, **attrs)
    @note_seq = (@note_seq || 0) + 1
    osis_ref ||= begin
      from = @note_seq % 20
      "Bible.KJV.John.3.16!#{from}-Bible.KJV.John.3.16!#{from + 3}"
    end
    color = Highlight::TOOLBAR_COLORS[(@note_seq / 20) % 4]
    highlight = create(:highlight, user: author, translation: translation, osis_ref: osis_ref, color: color)
    note = create(:note, user: author, visibility: :public_note, body: body, **attrs)
    create(:highlight_note, highlight: highlight, note: note)
    note
  end

  it "renders public notes with verse quote, citation, and author for anonymous visitors" do
    public_note!(body: "Grace upon grace")
    get "/community"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Grace upon grace")
    expect(response.body).to include("For God so loved the world")
    expect(response.body).to include("John 3:16")
    expect(response.body).to include("Apollos")
  end

  it "excludes private, friends, and hidden notes" do
    create(:note, user: author, visibility: :private_note, body: "Secret")
    create(:note, user: author, visibility: :friends_note, body: "For friends")
    hidden = public_note!(body: "Hidden thing")
    hidden.update!(hidden_at: Time.current)

    get "/community"

    expect(response.body).not_to include("Secret")
    expect(response.body).not_to include("For friends")
    expect(response.body).not_to include("Hidden thing")
  end

  it "sorts by recency by default and by popularity with sort=top" do
    older = public_note!(body: "Older note", created_at: 2.days.ago)
    newer = public_note!(body: "Newer note")
    create(:upvote, note: older)

    get "/community"
    expect(response.body.index("Newer note")).to be < response.body.index("Older note")

    get "/community", params: { sort: "top" }
    expect(response.body.index("Older note")).to be < response.body.index("Newer note")
  end

  it "filters by book" do
    acts = create(:book, translation: translation, osis_code: "Acts", name_en: "Acts", name_es: "Hechos", position: 44, testament: 1)
    acts_ch = create(:chapter, book: acts, number: 1)
    create(:verse, chapter: acts_ch, number: 1, body_text: "The former treatise", body_html: "The former treatise", osis_ref: "Bible.KJV.Acts.1.1")
    public_note!(body: "John note")
    public_note!(body: "Acts note", osis_ref: "Bible.KJV.Acts.1.1!0-Bible.KJV.Acts.1.1!7")

    get "/community", params: { book: "John" }

    expect(response.body).to include("John note")
    expect(response.body).not_to include("Acts note")
  end

  it "paginates with a load-more link" do
    26.times { |i| public_note!(body: "Note number #{i}") }

    get "/community"
    expect(response.body).to include("/community?page=2")

    get "/community", params: { page: 2 }
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("/community?page=3")
  end
end
