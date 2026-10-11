require "rails_helper"
require "axe-rspec"

RSpec.describe "Highlighted in Red reader", type: :system, js: true do
  let(:user)        { create(:user) }
  let(:translation) { create(:translation, :kjv) }
  let(:john)        { create(:book, :john, translation: translation) }
  let!(:john3)      { create(:chapter, book: john, number: 3) }
  let!(:john4)      { create(:chapter, book: john, number: 4) }
  let!(:john5)      { create(:chapter, book: john, number: 5) }

  def verse!(chapter, number, text, red: nil)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.KJV.John.#{chapter.number}.#{number}")
  end

  before do
    sign_in user
    verse!(john3, 15, "And this is the narration around it.")
    verse!(john3, 16, "For God so loved the world.", red: [ 0, 27 ])
    verse!(john4, 1, "When the Lord knew therefore.")
    verse!(john5, 8, "Jesus saith unto him, Rise, take up thy bed, and walk.", red: [ 22, 54 ])
  end

  it "opens from the ordinary reader and shows his words in red" do
    visit "/bible/kjv/john/3"
    click_on I18n.t("bible.reader.red.read_in_red")

    expect(page).to have_current_path("/red/kjv/john/3")
    expect(page).to have_content(/#{I18n.t("bible.reader.red.eyebrow")}/i)
    expect(page).to have_css("span.jesus-words", text: "For God so loved the world.")
    expect(page).to have_content("And this is the narration around it.")
  end

  it "hides the narration with 'His words only' and remembers the choice" do
    visit "/red/kjv/john/3"
    click_button I18n.t("bible.reader.red.words_only")

    expect(page).to have_no_content("And this is the narration around it.")
    expect(page).to have_content("For God so loved the world.")
    expect(page).to have_css("button[aria-pressed='true']", text: I18n.t("bible.reader.red.words_only"))

    visit "/red/kjv/john/5"
    expect(page).to have_css("button[aria-pressed='true']", text: I18n.t("bible.reader.red.words_only"))

    click_button I18n.t("bible.reader.red.words_only")
    visit "/red/kjv/john/3"
    expect(page).to have_content("And this is the narration around it.")
  end

  it "steps to the next chapter with red text, skipping one without" do
    visit "/red/kjv/john/3"
    first("a", text: /next/i).click

    expect(page).to have_current_path("/red/kjv/john/5")
    expect(page).to have_css("span.jesus-words", text: "Rise, take up thy bed, and walk.")
  end

  it "returns to the whole chapter" do
    visit "/red/kjv/john/3"
    click_on I18n.t("bible.reader.red.whole_chapter")

    expect(page).to have_current_path("/bible/kjv/john/3")
    expect(page).to have_no_content(/#{I18n.t("bible.reader.red.eyebrow")}/i)
  end

  it "is axe-clean and fits a phone-width screen" do
    original = page.driver.browser.manage.window.size
    page.driver.browser.manage.window.resize_to(375, 800)
    visit "/red/kjv/john/3"

    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
    overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
    expect(overflow).to be <= 1
  ensure
    page.driver.browser.manage.window.resize_to(original.width, original.height) if original
  end

  it "keeps highlighting working under the lens" do
    v16 = Verse.find_by!(osis_ref: "Bible.KJV.John.3.16")
    visit "/red/kjv/john/3"

    page.execute_script(<<~JS)
      (function() {
        const node = document.querySelector("[data-verse-id='#{v16.id}'] .jesus-words").firstChild;
        const range = document.createRange();
        range.setStart(node, 0);
        range.setEnd(node, 7);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        document.dispatchEvent(new Event("selectionchange"));
        document.querySelector("[data-highlight-target='chapter']").dispatchEvent(new MouseEvent("mouseup", { bubbles: true }));
      })()
    JS
    expect(page).to have_css("[data-highlight-target='toolbar']:not([hidden])", visible: :all)
    find("[data-highlight-target='toolbar'] [data-highlight-default]", visible: :all).click

    expect(page).to have_css("[data-verse-id='#{v16.id}'] [data-highlight-ids]", text: "For God")
    expect(user.highlights.pick(:osis_ref)).to eq("Bible.KJV.John.3.16!0-Bible.KJV.John.3.16!7")
    # The verse was replaced in place; the lens must still be on.
    expect(page).to have_css("article.red-lens")
    expect(page).to have_css("[data-verse-id='#{v16.id}'] .jesus-words")
  end
end
