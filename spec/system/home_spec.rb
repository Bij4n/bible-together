require "rails_helper"

# Homepage is hero copy, three bullet points, optional community notes,
# and donate CTA. Full tour lives on /how-it-works.
RSpec.describe "Home page", type: :system do
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

  it "renders the hero copy" do
    visit "/"

    expect(page).to have_css("h1", text: I18n.t("home.welcome"))
    expect(page).to have_content(I18n.t("home.subhead"))
  end

  it "renders the landing points" do
    visit "/"

    I18n.t("home.landing.points").each do |point|
      expect(page).to have_content(point[:title])
      expect(page).to have_content(point[:body])
    end
  end

  it "renders the hero product preview" do
    visit "/"

    within(".landing-hero") do
      expect(page).to have_css(".landing-preview")
    end
  end

  it "does not render removed marketing sections" do
    visit "/"

    expect(page).not_to have_css("[data-testid='hero-empty-state']")
    expect(page).not_to have_css(".landing-hero-grid")
    expect(page).not_to have_css("section#about")
  end

  it "renders marketing pages with the marketing surface class" do
    visit "/"
    expect(page).to have_css("body.marketing-surface")
  end

  it "renders the same wordmark in header and footer" do
    visit "/"

    within("header") do
      expect(page).to have_link(I18n.t("app.name"), href: "/")
      expect(page).to have_css("a.wordmark")
      expect(page).not_to have_css("svg.wordmark-mark")
    end

    within("footer") do
      expect(page).to have_link(I18n.t("app.name"), href: "/")
      expect(page).to have_css("a.wordmark")
      expect(page).not_to have_css("svg.wordmark-mark")
    end
  end

  it "does not render the full how-it-works feature grid on the homepage" do
    visit "/"

    expect(page).not_to have_content(I18n.t("home.features.semantic_search.title"))
  end

  it "links 'How it works' to /how-it-works from the hero" do
    visit "/"

    within(".landing-hero") do
      link = find_link(I18n.t("home.cta_how_it_works"))
      expect(link[:href]).to eq("/how-it-works")
    end
  end

  it "renders the bottom Donate CTA when an active address exists" do
    BitcoinAddress.rotate_to!(address: "bc1qfzfen6peqgqmc03gj2jsu0zc96s49dwgahvu2l")
    visit "/"

    expect(page).to have_content(I18n.t("home.donate_cta.heading"))
    expect(page).to have_content(I18n.t("home.donate_cta.body"))

    expect(page).to have_css("section[data-section='donate-cta'].donate-callout")
    within("section[data-section='donate-cta']") do
      expect(page).to have_content("hosting and the bills")
      expect(page).not_to have_content("donations keep it open")
    end
  end

  it "hides the bottom Donate CTA when no active address exists" do
    visit "/"

    expect(page).not_to have_content(I18n.t("home.donate_cta.heading"))
    expect(page).not_to have_css("[data-section='donate-cta']")
  end

  it "lands the hero CTA on the reader (community layer for guests)" do
    visit "/"

    within(".landing-hero") { click_on I18n.t("home.cta_public_bible") }
    expect(page).to have_current_path("/bible/kjv/gen/1?layer=community")
  end

  it "lands the bottom donate-CTA button on /donate" do
    BitcoinAddress.rotate_to!(address: "bc1qfzfen6peqgqmc03gj2jsu0zc96s49dwgahvu2l")
    visit "/"

    within("section[data-section='donate-cta']") do
      click_on I18n.t("home.donate_cta.button")
    end
    expect(page).to have_current_path("/donate")
  end

  context "when an active BitcoinAddress exists" do
    before { BitcoinAddress.rotate_to!(address: "bc1qfzfen6peqgqmc03gj2jsu0zc96s49dwgahvu2l") }

    it "shows the footer Donate link on the homepage" do
      visit "/"

      within("footer") do
        expect(page).to have_link(I18n.t("layout.donate_link"), href: "/donate")
      end
    end
  end
end
