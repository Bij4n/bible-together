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

  it "renders the page title and subhead" do
    visit "/how-it-works"

    expect(page).to have_css("h1", text: I18n.t("home.how_it_works_title"))
    expect(page).to have_content(I18n.t("home.subhead"))
  end

  it "renders the three how-it-works step bodies" do
    visit "/how-it-works"

    expect(page).to have_content("Pick a translation. Open a chapter.")
    expect(page).to have_content("Select what struck you. Write what it meant. Yours by default.")
    expect(page).to have_content("With one person. With a group. With everyone.")
  end

  it "renders all 7 feature cards" do
    visit "/how-it-works"

    expect(page).to have_content(I18n.t("home.features.highlights.title"))
    expect(page).to have_content(I18n.t("home.features.notes.title"))
    expect(page).to have_content(I18n.t("home.features.groups.title"))
    expect(page).to have_content(I18n.t("home.features.public.title"))
    expect(page).to have_content(I18n.t("home.features.bilingual.title"))
    expect(page).to have_content(I18n.t("home.features.keyword_search.title"))
    expect(page).to have_content(I18n.t("home.features.semantic_search.title"))
  end

  it "groups feature cards into 'For yourself' and 'With others' subgroups" do
    visit "/how-it-works"

    expect(page).to have_css("h3", text: I18n.t("home.features.for_yourself"))
    expect(page).to have_css("h3", text: I18n.t("home.features.with_others"))
  end

  it "renders the About section" do
    visit "/how-it-works"

    paragraphs = all("section#about p", visible: :all)
    expect(paragraphs.size).to eq(5)
    expect(paragraphs[0].text).to include("scripture is meant to be read with someone")
    expect(paragraphs[1].text).to include("verse that wrecks you wrecks somebody else")
  end

  it "renders the softened public-notes card copy" do
    visit "/how-it-works"

    expect(page).to have_content("someone whose life looks nothing like yours")
    expect(page).not_to have_content("widow who lost her husband")
    expect(page).not_to have_content("kid finding their faith")
  end

  it "lands every feature-card link on its claimed destination" do
    expected_destinations = {
      "highlights"      => "/public/bible/kjv/gen/1",
      "notes"           => "/public/bible/kjv/gen/1",
      "groups"          => "/groups",
      "public"          => "/public/bible/kjv/gen/1",
      "bilingual"       => "/public/bible/rv1909/gen/1",
      "keyword_search"  => "/search",
      "semantic_search" => "/search"
    }

    expected_destinations.each do |key, path|
      visit "/how-it-works"

      title = I18n.t("home.features.#{key}.title")
      link = find_link(title)
      expect(link[:href]).to eq(path), "expected feature card '#{title}' to link to #{path}, was #{link[:href]}"
    end
  end
end
