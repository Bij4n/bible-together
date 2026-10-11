require "rails_helper"
require "axe-rspec"

RSpec.describe "Highlighted in Red parables", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:kjv) { create(:translation, :kjv) }

  def book!(code, en, es, position)
    create(:book, translation: kjv, osis_code: code, name_en: en, name_es: es, position: position, testament: :new)
  end

  def verse!(book, chapter_number, number, text, red: true)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ [ 0, text.length ] ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    matthew = book!("Matt", "Matthew", "Mateo", 40)
    mark    = book!("Mark", "Mark", "Marcos", 41)
    verse!(matthew, 13, 2, "And great multitudes were gathered together unto him.", red: false)
    verse!(matthew, 13, 3, "Behold, a sower went forth to sow;")
    (4..9).each { |n| verse!(matthew, 13, n, "Matthew sower verse #{n}.") }
    (3..9).each { |n| verse!(mark, 4, n, "Mark sower verse #{n}.") }
    (24..30).each { |n| verse!(matthew, 13, n, "The wheat and the weeds, verse #{n}.") }
    sign_in user
  end

  it "opens a parable from the list and reads it in another gospel" do
    visit "/red/parables"
    click_on "The Sower"

    expect(page).to have_current_path("/red/parables/sower")
    expect(page).to have_css("h1", text: "The Sower")
    expect(page).to have_css("span.jesus-words", text: "Behold, a sower went forth to sow;")
    expect(page).to have_no_content("And great multitudes were gathered")

    within(".passage-tellings") { click_on "Mark 4:3–9" }
    expect(page).to have_current_path("/red/parables/sower?in=mark")
    expect(page).to have_content("Mark sower verse 3.")
  end

  it "shows his explanation under the parable" do
    matthew = Book.find_by!(osis_code: "Matt")
    verse!(matthew, 13, 18, "Hear ye therefore the parable of the sower.")
    verse!(matthew, 13, 19, "When any one heareth the word of the kingdom.")

    visit "/red/parables/sower"

    expect(page).to have_css(".passage-explanation", text: /#{I18n.t("red.explained")}/i)
    expect(page).to have_css("span.jesus-words", text: "Hear ye therefore the parable of the sower.")
  end

  it "steps to the next parable and back to the list" do
    visit "/red/parables/sower"
    within(".passage-nav") { click_on "The Wheat and the Weeds" }

    expect(page).to have_current_path("/red/parables/wheat-and-weeds")
    expect(page).to have_content("The wheat and the weeds, verse 24.")

    click_on I18n.t("red.parables.all")
    expect(page).to have_current_path("/red/parables")
  end

  it "opens the passage in its chapter" do
    visit "/red/parables/sower"
    click_on I18n.t("bible.reader.red.in_its_chapter")

    expect(page).to have_current_path("/red/kjv/matt/13")
    expect(page).to have_content("And great multitudes were gathered")
  end

  it "saves a highlight made on a parable page" do
    v3 = Verse.find_by!(osis_ref: "Bible.KJV.Matt.13.3")
    visit "/red/parables/sower"

    page.execute_script(<<~JS)
      (function() {
        const node = document.querySelector("[data-verse-id='#{v3.id}'] .jesus-words").firstChild;
        const range = document.createRange();
        range.setStart(node, 0);
        range.setEnd(node, 6);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        document.dispatchEvent(new Event("selectionchange"));
        document.querySelector("[data-highlight-target='chapter']").dispatchEvent(new MouseEvent("mouseup", { bubbles: true }));
      })()
    JS
    expect(page).to have_css("[data-highlight-target='toolbar']:not([hidden])", visible: :all)
    find("[data-highlight-target='toolbar'] [data-highlight-default]", visible: :all).click

    expect(page).to have_css("[data-verse-id='#{v3.id}'] [data-highlight-ids]", text: "Behold")
    expect(user.highlights.pick(:osis_ref)).to eq("Bible.KJV.Matt.13.3!0-Bible.KJV.Matt.13.3!6")
    expect(page).to have_css("article.red-lens")
  end

  it "is axe-clean and fits a phone-width screen" do
    at_window_size(375, 800) do
      [ "/red/parables", "/red/parables/sower" ].each do |path|
        visit path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
        expect(overflow).to be <= 1, "#{path} overflows by #{overflow}px"
      end
    end
  end
end
