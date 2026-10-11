require "rails_helper"
require "axe-rspec"

RSpec.describe "Studying Highlighted in Red", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:kjv) { create(:translation, :kjv) }

  def verse!(book, chapter_number, number, text, red: nil)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    genesis = create(:book, translation: kjv, osis_code: "Gen", name_en: "Genesis", name_es: "Génesis", position: 1, testament: :old)
    matthew = create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo", position: 40, testament: :new)
    john    = create(:book, translation: kjv, osis_code: "John", name_en: "John", name_es: "Juan", position: 43, testament: :new)
    verse!(genesis, 1, 1, "In the beginning God created the heaven and the earth.")
    verse!(matthew, 4, 18, "And Jesus, walking by the sea of Galilee, saw two brethren.")
    verse!(matthew, 4, 19, "And he saith unto them, Follow me.", red: [ 24, 34 ])
    verse!(matthew, 5, 1, "And seeing the multitudes, he went up into a mountain.")
    verse!(john, 3, 16, "For God so loved the world.", red: [ 0, 27 ])
    sign_in user
  end

  it "lets a reader make Highlighted in Red what Read opens" do
    visit "/settings"
    choose I18n.t("settings.sections.study_focus.options.red")
    expect(page).to have_checked_field(I18n.t("settings.sections.study_focus.options.red"))
    # The radio auto-submits; wait for the save to land.
    Timeout.timeout(5) { sleep 0.05 until user.reload.focus_red? }

    visit "/"
    within("header.site-header nav.site-nav") { click_on I18n.t("layout.read_link") }
    expect(page).to have_current_path("/red/kjv/matt/4")
    expect(page).to have_css("span.jesus-words", text: "Follow me.")
  end

  it "starts a study of Highlighted in Red and reads it under the lens" do
    visit "/studies/new"
    fill_in "Name", with: "Red letters"
    find("input[value='invite_only']").click
    choose I18n.t("groups.focus.red")
    find('input[type="submit"]').click

    expect(page).to have_content(/red letters/i)
    click_on I18n.t("groups.open_study_bible")

    group = Group.find_by!(name: "Red letters")
    expect(page).to have_current_path("/studies/#{group.id}/bible/kjv/matt/4")
    expect(page).to have_css("article.red-lens")
    expect(page).to have_css("span.jesus-words", text: "Follow me.")

    click_button I18n.t("bible.reader.red.words_only")
    expect(page).to have_no_content("And Jesus, walking by the sea of Galilee")
    click_button I18n.t("bible.reader.red.words_only")

    within("nav.study-chapter-nav") { click_on I18n.t("bible.reader.next_chapter") }
    expect(page).to have_current_path("/studies/#{group.id}/bible/kjv/john/3")
  end

  it "is axe-clean and fits a phone-width screen" do
    group = create(:group, owner: user, focus: :red)

    at_window_size(375, 800) do
      [ "/settings", "/studies/new", "/studies/#{group.id}", "/studies/#{group.id}/bible/kjv/matt/4" ].each do |path|
        visit path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
        expect(overflow).to be <= 1, "#{path} overflows by #{overflow}px"
      end
    end
  end
end
