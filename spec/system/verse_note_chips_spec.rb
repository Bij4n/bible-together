require "rails_helper"

# Design-v3 note chips: a verse that has notes in the active layer
# carries a small count chip at its end. On the personal reader the
# chip opens the note in the slide-in panel (turbo frame); on the
# community and study layers it anchors to the note's card in the
# list below the chapter.
RSpec.describe "Verse note chips", type: :system do
  let(:user) { create(:user) }
  let(:translation) { create(:translation, :kjv) }
  let(:book) { create(:book, :john, translation: translation) }
  let(:chapter) { create(:chapter, book: book, number: 3) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   osis_ref: "Bible.KJV.John.3.16")
  end

  def attach_note(author, visibility:, color: "yellow")
    highlight = create(:highlight, user: author, translation: translation,
                                   osis_ref: "Bible.KJV.John.3.16",
                                   color: color)
    note = create(:note, user: author, body: "<p>A thought</p>", visibility: visibility)
    create(:highlight_note, highlight: highlight, note: note)
    note
  end

  it "shows a chip on the personal reader that opens the note panel" do
    note = attach_note(user, visibility: "private_note")
    sign_in user

    visit "/bible/kjv/john/3"

    chip = find(".verse-note-chip")
    expect(chip.text).to eq("1")
    expect(chip[:href]).to include("/notes/#{note.id}/edit")
    expect(chip["data-turbo-frame"]).to eq("note_panel")
  end

  it "shows a chip on the community layer that anchors to the note card" do
    author = create(:user)
    note = attach_note(author, visibility: "public_note")

    visit "/public/bible/kjv/john/3"

    chip = find(".verse-note-chip")
    expect(chip[:href]).to end_with("#note_#{note.id}")
    expect(page).to have_css("li#note_#{note.id}")
  end

  it "shows a chip on the study layer that anchors to the note card" do
    group = create(:group, owner: user)
    note = attach_note(user, visibility: "shared_groups")
    create(:note_share, note: note, shareable: group)
    sign_in user

    visit "/studies/#{group.id}/bible/kjv/john/3"

    chip = find(".verse-note-chip")
    expect(chip[:href]).to end_with("#note_#{note.id}")
  end

  it "shows no chip when the verse has no notes" do
    sign_in user
    visit "/bible/kjv/john/3"

    expect(page).not_to have_css(".verse-note-chip")
  end
end
