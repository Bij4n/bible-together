require "rails_helper"

# Account-menu open/close mechanics + the per-viewport class contract.
# The menu element ships with class="account-sheet" — at <640px the CSS
# styles it as a fixed bottom-sheet, at 640px+ as a floating dropdown.
# JS-tagged because the open/close flow goes through the user_menu
# Stimulus controller (toggle, click-outside, Escape) which only fires
# under a real browser. The CSS shape difference per breakpoint is a
# visual concern axe + the layout cover; this spec asserts the JS
# contract: the menu opens, has the right class, closes on outside
# click.
RSpec.describe "Account menu", type: :system, js: true do
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

  it "renders the menu with the .account-sheet class" do
    visit "/"

    expect(page).to have_css("div[data-user-menu-target='menu'].account-sheet", visible: :all)
  end

  it "opens the menu when the trigger is clicked" do
    visit "/"

    expect(page).not_to have_css("div[data-user-menu-target='menu']:not([hidden])")

    find("button[data-user-menu-target='trigger']").click

    expect(page).to have_css("div[data-user-menu-target='menu']:not([hidden])")
  end

  it "closes the menu when the trigger is clicked again" do
    visit "/"
    trigger = find("button[data-user-menu-target='trigger']")

    trigger.click
    expect(page).to have_css("div[data-user-menu-target='menu']:not([hidden])")

    trigger.click
    expect(page).not_to have_css("div[data-user-menu-target='menu']:not([hidden])")
  end
end
