require "rails_helper"
require "axe-rspec"

RSpec.describe "Highlighted in Red encounters and themes", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:kjv) { create(:translation, :kjv) }

  def verse!(book, chapter_number, number, text, red: nil)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    luke = create(:book, translation: kjv, osis_code: "Luke", name_en: "Luke", name_es: "Lucas", position: 42, testament: :new)
    verse!(luke, 19, 1, "And Jesus entered and passed through Jericho.")
    (2..8).each { |n| verse!(luke, 19, n, "Zacchaeus narration #{n}.") }
    verse!(luke, 19, 9, "And Jesus said unto him, This day is salvation come to this house.", red: [ 25, 66 ])
    verse!(luke, 19, 10, "For the Son of man is come to seek and to save that which was lost.", red: [ 0, 67 ])
    sign_in user
  end

  it "goes from a theme to an encounter, where the story stays visible" do
    visit "/red/themes"
    click_on "He welcomes the outsider"
    expect(page).to have_content(/#{I18n.t("red.themes.did")}/i)

    click_on "Zacchaeus"
    expect(page).to have_current_path("/red/encounters/zacchaeus")
    expect(page).to have_css("h1", text: "Zacchaeus")
    expect(page).to have_content("And Jesus entered and passed through Jericho.")
    expect(page).to have_css("span.jesus-words", text: "This day is salvation come to this house.")
    expect(page).to have_no_button(I18n.t("bible.reader.red.words_only"))
  end

  it "keeps an encounter's story visible even after 'His words only' was chosen elsewhere" do
    visit "/red/kjv/luke/19"
    click_button I18n.t("bible.reader.red.words_only")
    expect(page).to have_no_content("Zacchaeus narration 2.")

    within(".chapter-body") { click_on "Zacchaeus" }
    expect(page).to have_current_path("/red/encounters/zacchaeus?translation=kjv")
    expect(page).to have_content("Zacchaeus narration 2.")

    visit "/red/kjv/luke/19"
    click_button I18n.t("bible.reader.red.words_only")
  end

  it "moves between the lists" do
    visit "/red/encounters"
    within(".red-sections") { click_on I18n.t("red.sayings.title") }
    expect(page).to have_current_path("/red/sayings")
    expect(page).to have_content("The Beatitudes")

    within(".red-sections") { click_on I18n.t("red.themes.title") }
    expect(page).to have_current_path("/red/themes")
  end

  it "is axe-clean and fits a phone-width screen" do
    at_window_size(375, 800) do
      [ "/red/encounters", "/red/sayings", "/red/themes", "/red/themes/forgiveness",
        "/red/encounters/zacchaeus", "/red/kjv/luke/19" ].each do |path|
        visit path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
        expect(overflow).to be <= 1, "#{path} overflows by #{overflow}px"
      end
    end
  end
end
