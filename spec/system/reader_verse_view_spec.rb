require "rails_helper"

# Verse view is the only reader layout: every verse renders as its own
# block, and the old continuous-prose toggle is gone. (It used to be a
# localStorage preference switched by the reader-prefs controller.)
RSpec.describe "Reader verse view", type: :system, js: true do
  let(:user) { create(:user) }
  let(:translation) { create(:translation, :kjv) }
  let(:book) { create(:book, :john, translation: translation) }
  let(:chapter) { create(:chapter, book: book, number: 3) }

  before do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   osis_ref: "Bible.KJV.John.3.16")
    sign_in user
  end

  it "always renders verses as their own block and offers no view toggle" do
    visit "/bible/kjv/john/3"

    expect(page).to have_css(".chapter-body .verse")
    expect(page).not_to have_css("[data-action='reader-prefs#toggleVerseBlocks']")
    expect(page).not_to have_css("[data-controller~='reader-prefs']")

    verse_display = page.evaluate_script(
      "getComputedStyle(document.querySelector('.chapter-body .verse')).display"
    )
    expect(verse_display).to eq("block")
  end
end
