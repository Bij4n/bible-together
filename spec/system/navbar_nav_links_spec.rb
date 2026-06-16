require "rails_helper"

# Top-level nav IA: Read · Study · Explore (+ account on desktop).
RSpec.describe "Navbar nav links", type: :system, js: true do

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

  before { page.driver.browser.manage.window.resize_to(1280, 800) }

  context "when signed out" do
    it "shows the Read link" do
      visit "/"
      within("header.site-header nav") do
        expect(page).to have_link(I18n.t("layout.read_link"), href: bible_entry_path)
      end
    end

    it "routes Study to How it works (studies anchor)" do
      visit "/"
      within("header.site-header nav") do
        expect(page).to have_link(I18n.t("layout.study_menu"), href: %r{/how-it-works#studies})
      end
    end

    it "keeps Community under Explore, not the top rail" do
      visit "/"
      within("header.site-header nav") do
        expect(page).not_to have_link(I18n.t("layout.community_link"), href: community_path)
      end
    end
  end

  context "when signed in" do
    before { sign_in create(:user) }

    it "shows the Read link" do
      visit "/"
      within("header.site-header nav") do
        expect(page).to have_link(I18n.t("layout.read_link"))
      end
    end

    it "opens Study destinations from the Study menu" do
      visit "/"
      within("header.site-header") { click_button I18n.t("layout.study_menu") }
      within("[data-user-menu-target=\"menu\"]:not([hidden])") do
        expect(page).to have_link(I18n.t("layout.my_studies_link"), href: groups_path)
      end
    end

    it "keeps My notes out of the nav rail" do
      visit "/"
      expect(page).not_to have_css("header.site-header nav > a[href=\"#{notes_path}\"]")
    end

    it "puts My notes in the Study menu" do
      visit "/"
      within("header.site-header") { click_button I18n.t("layout.study_menu") }
      within("[data-user-menu-target=\"menu\"]:not([hidden])") do
        expect(page).to have_link(I18n.t("layout.my_notes_link"), href: notes_path)
      end
    end

    it "marks Read active on the reader" do
      visit bible_chapter_path(translation: "kjv", book: "gen", chapter: 1)
      within("header.site-header nav") do
        link = find_link(I18n.t("layout.read_link"))
        expect(link[:class]).to include("site-nav-link--active")
      end
    end

    it "does not mark Read active on the marketing homepage" do
      visit "/"
      within("header.site-header nav") do
        link = find_link(I18n.t("layout.read_link"))
        expect(link[:class]).not_to include("site-nav-link--active")
      end
    end
  end
end
