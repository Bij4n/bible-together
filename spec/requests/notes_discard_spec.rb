require "rails_helper"

RSpec.describe "Notes discard draft", type: :request do
  let(:user) { create(:user) }
  let(:translation) { create(:translation, :kjv) }

  before { sign_in user }

  it "removes orphan highlights created for an abandoned note" do
    highlight = create(:highlight, user: user, translation: translation,
                                 osis_ref: "Bible.KJV.John.3.16!0-Bible.KJV.John.3.16!3",
                                 color: :yellow)

    expect {
      post discard_draft_notes_path, params: { highlight_ids: [ highlight.id ] },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    }.to change(Highlight, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
  end

  it "does not remove highlights that already have notes" do
    highlight = create(:highlight, user: user, translation: translation,
                                 osis_ref: "Bible.KJV.John.3.16!0-Bible.KJV.John.3.16!3",
                                 color: :yellow)
    note = create(:note, user: user, body: "<p>Kept</p>")
    create(:highlight_note, highlight: highlight, note: note)

    expect {
      post discard_draft_notes_path, params: { highlight_ids: [ highlight.id ] }
    }.not_to change(Highlight, :count)
  end
end
