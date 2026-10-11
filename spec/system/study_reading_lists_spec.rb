require "rails_helper"
require "axe-rspec"

RSpec.describe "A study that works through a list", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:kjv) { create(:translation, :kjv) }

  def verse!(book, chapter_number, number, text, red: true)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ [ 0, text.length ] ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    matthew = create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo", position: 40, testament: :new)
    (14..16).each { |n| verse!(matthew, 5, n, "Lamp verse #{n}.") }
    (24..27).each { |n| verse!(matthew, 7, n, "Builders verse #{n}.") }
    sign_in user
  end

  it "is started from the form, read passage by passage, and remembers where the study is" do
    visit "/studies/new"
    fill_in "Name", with: "Parables together"
    find("input[value='invite_only']").click
    select I18n.t("red.parables.title"), from: I18n.t("groups.focus.label")
    find('input[type="submit"]').click

    expect(page).to have_content(/parables together/i)
    expect(page).to have_css(".study-reading-list li[aria-current='step']", text: "The Lamp on a Stand")

    click_on I18n.t("groups.reading_list.open_current", title: "The Lamp on a Stand")
    group = Group.find_by!(name: "Parables together")
    expect(page).to have_current_path("/studies/#{group.id}/passages/lamp-on-a-stand")
    expect(page).to have_css("h1", text: "The Lamp on a Stand")
    expect(page).to have_css("span.jesus-words", text: "Lamp verse 14.")
    expect(page).to have_content(I18n.t("groups.reading_list.we_are_here"))

    within("nav.study-passage-nav") { click_on "The Wise and Foolish Builders" }
    expect(page).to have_current_path("/studies/#{group.id}/passages/wise-and-foolish-builders")
    expect(page).to have_css("span.jesus-words", text: "Builders verse 24.")

    click_button I18n.t("groups.reading_list.mark_here")
    expect(page).to have_content(I18n.t("groups.reading_list.we_are_here"))
    expect(page).to have_no_button(I18n.t("groups.reading_list.mark_here"))

    visit "/studies/#{group.id}"
    expect(page).to have_css(".study-reading-list li[aria-current='step']", text: "The Wise and Foolish Builders")
  end

  it "is axe-clean and fits a phone-width screen" do
    group = create(:group, owner: user, reading_list: "parables")

    at_window_size(375, 800) do
      [ "/studies/new", "/studies/#{group.id}", "/studies/#{group.id}/passages/lamp-on-a-stand" ].each do |path|
        visit path
        expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
        overflow = page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")
        expect(overflow).to be <= 1, "#{path} overflows by #{overflow}px"
      end
    end
  end
end
