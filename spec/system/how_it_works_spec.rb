require "rails_helper"

RSpec.describe "How it works page", type: :system do
  let!(:translation_kjv) { create(:translation, :kjv) }
  let!(:translation_rv1909) { create(:translation, :rv1909) }
  let!(:book_genesis_kjv) { create(:book, :genesis, translation: translation_kjv) }
  let!(:chapter_kjv)     { create(:chapter, book: book_genesis_kjv, number: 1) }
  let!(:verse_kjv) do
    create(:verse, chapter: chapter_kjv, number: 1,
                   body_text: "In the beginning",
                   body_html: "In the beginning",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.Gen.1.1")
  end
  let!(:book_genesis_rv) { create(:book, :genesis, translation: translation_rv1909) }
  let!(:chapter_rv)      { create(:chapter, book: book_genesis_rv, number: 1) }
  let!(:verse_rv) do
    create(:verse, chapter: chapter_rv, number: 1,
                   body_text: "En el principio",
                   body_html: "En el principio",
                   red_letter_ranges: [],
                   osis_ref: "Bible.RV1909.Gen.1.1")
  end

  it "renders the page title and intro" do
    visit "/how-it-works"

    expect(page).to have_content(I18n.t("home.how_it_works_title"))
    expect(page).to have_css("h1", text: I18n.t("home.landing.how_page_intro"))
  end

  it "renders the three steps" do
    visit "/how-it-works"

    expect(page).to have_content(I18n.t("home.how.step_1_title"))
    expect(page).to have_content(I18n.t("home.how.step_1_body"))
    expect(page).to have_content(I18n.t("home.how.step_2_title"))
    expect(page).to have_content(I18n.t("home.how.step_2_body"))
    expect(page).to have_content(I18n.t("home.how.step_3_title"))
    expect(page).to have_content(I18n.t("home.how.step_3_body"))
  end

  it "renders the included feature list" do
    visit "/how-it-works"

    I18n.t("home.landing.feature_list").each do |item|
      expect(page).to have_content(item)
    end
  end

  it "does not render an embedded About section or feature demos" do
    visit "/how-it-works"

    expect(page).not_to have_css("section#about")
    expect(page).not_to have_css(".landing-value-demo")
  end

  it "links to the reader from the page CTA" do
    visit "/how-it-works"

    click_on I18n.t("home.cta_public_bible"), match: :first
    expect(page).to have_current_path("/bible/kjv/gen/1", ignore_query: true)
  end
end
