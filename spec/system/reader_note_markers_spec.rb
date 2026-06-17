require "rails_helper"

# Verses with notes show a persistent left accent bar and count chip
# so readers can keep going and still see where they left notes.
RSpec.describe "Reader note markers", type: :system, js: true do
  let(:user) { create(:user) }
  let(:translation) { create(:translation, :kjv) }
  let(:book) { create(:book, :john, translation: translation) }
  let(:chapter) { create(:chapter, book: book, number: 3) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.John.3.16")
  end

  before { sign_in user }

  it "marks a verse with a note using the note color accent and chip" do
    highlight = create(:highlight, user: user, translation: translation,
                                 osis_ref: "Bible.KJV.John.3.16!0-Bible.KJV.John.3.16!3",
                                 color: :yellow)
    note = create(:note, user: user, body: "<p>Prayer</p>", color: "teal", label: "Prayer")
    create(:highlight_note, highlight: highlight, note: note)

    visit "/bible/kjv/john/3"

    verse_el = find("[data-verse-id='#{verse.id}']")
    expect(verse_el[:class]).to include("verse-has-note", "note-marker-teal")
    expect(page).to have_css(".verse-note-chip.note-chip-teal", text: "1")
  end

  it "clears the verse marker after discarding a draft note" do
    highlight = create(:highlight, user: user, translation: translation,
                                 osis_ref: "Bible.KJV.John.3.16!0-Bible.KJV.John.3.16!3",
                                 color: :yellow)

    visit "/bible/kjv/john/3"
    page.execute_script(<<~JS)
      document.getElementById("note_panel").setAttribute("src", "/notes/new?highlight_ids[]=#{highlight.id}")
    JS

    expect(page).to have_css("[data-note-panel-draft-value='true']", wait: 5)
    click_button I18n.t("notes.cancel")

    expect(page).not_to have_css("[data-verse-id='#{verse.id}'].verse-has-note", wait: 5)
    expect(Highlight.exists?(highlight.id)).to be false
  end
end
