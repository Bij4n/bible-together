require "rails_helper"

# Sticky-on-scroll header behavior. The header sits flush at rest and
# pops a bottom border once the page has scrolled past the threshold —
# the visual signal that the header has lifted off the top of the page.
# The site_header Stimulus controller toggles `.scrolled` based on
# window.scrollY > 16; CSS handles the rest. JS-tagged because the
# class toggle requires a real scroll event under a JS-driven browser.
RSpec.describe "Site header sticky behavior", type: :system, js: true do
  let!(:translation) { create(:translation, :kjv) }
  let!(:book)        { create(:book, :genesis, translation: translation) }
  let!(:chapter)     { create(:chapter, book: book, number: 1) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 1,
                   body_text: "In the beginning",
                   body_html: "In the beginning",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.Gen.1.1")
  end

  it "renders the header as .site-header without .scrolled at rest" do
    visit "/"

    expect(page).to have_css("header.site-header")
    expect(page).not_to have_css("header.site-header.scrolled")
  end

  it "adds .scrolled to the header after scrolling past the 16px threshold" do
    visit "/"

    # 100px is comfortably past the 16px threshold and within the
    # homepage's actual scrollable height; the controller is a passive
    # listener so the assertion may need a frame to settle, which
    # Capybara's default wait covers.
    page.execute_script("window.scrollTo(0, 100)")

    expect(page).to have_css("header.site-header.scrolled")
  end
end
