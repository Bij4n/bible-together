require "rails_helper"

RSpec.describe "Site navigation", type: :system, js: true do
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

  it "labels the header nav for assistive tech" do
    visit "/"
    expect(page).to have_css("nav.site-nav[aria-label='#{I18n.t("layout.main_nav")}']")
  end

  context "desktop header" do
    before { page.driver.browser.manage.window.resize_to(1280, 800) }

    context "when signed out" do
      it "shows Read, Study, Explore, search icon, Sign in, and Start reading" do
        visit "/"

        within("header.site-header") do
          expect(page).to have_link(I18n.t("layout.read_link"))
          expect(page).to have_link(I18n.t("layout.study_menu"), href: %r{/how-it-works#studies})
          expect(page).to have_css("button[aria-label='#{I18n.t("layout.open_explore_menu")}']")
          expect(page).to have_link(I18n.t("auth.sign_in"))
          expect(page).to have_link(I18n.t("layout.start_reading_link"))
          expect(page).not_to have_css("button[aria-label='#{I18n.t("layout.open_account_menu")}']")
        end
      end

      it "lists explore destinations in the Explore menu" do
        visit "/"
        find("button[aria-label='#{I18n.t("layout.open_explore_menu")}']").click

        within("[data-user-menu-target='menu']:not([hidden])") do
          expect(page).to have_link(I18n.t("layout.public_notes_link"))
          expect(page).to have_link(I18n.t("layout.community_bible_link"))
          expect(page).to have_link(I18n.t("search.submit"))
          expect(page).to have_link(I18n.t("layout.discover_studies_link"))
        end
      end
    end

    context "when signed in" do
      before { sign_in create(:user) }

      it "shows avatar menu instead of hamburger account nav" do
        visit "/"

        within("header.site-header") do
          expect(page).to have_css("button[aria-label='#{I18n.t("layout.open_account_menu")}']")
          expect(page).not_to have_button(I18n.t("layout.open_menu"))
        end
      end

      it "lists study destinations in the Study menu" do
        visit "/"
        find("button[aria-label='#{I18n.t("layout.open_study_menu")}']").click

        within("[data-user-menu-target='menu']:not([hidden])") do
          expect(page).to have_link(I18n.t("layout.my_notes_link"))
          expect(page).to have_link(I18n.t("layout.my_studies_link"))
          expect(page).to have_link(I18n.t("layout.start_study_link"))
          expect(page).to have_link(I18n.t("layout.join_with_code_link"))
        end
      end

      it "does not duplicate Read or Studies links in the avatar menu" do
        visit "/"
        find("button[aria-label='#{I18n.t("layout.open_account_menu")}']").click

        within("[data-user-menu-target='menu']:not([hidden])") do
          expect(page).to have_link(I18n.t("auth.settings"))
          expect(page).not_to have_link(I18n.t("layout.read_link"))
          expect(page).not_to have_link(I18n.t("layout.my_notes_link"))
          expect(page).not_to have_link(I18n.t("layout.public_notes_link"))
        end
      end
    end
  end

  context "mobile tab bar" do
    before { page.driver.browser.manage.window.resize_to(390, 844) }

    it "renders Read, Study, Explore, and You tabs" do
      visit "/"

      within("nav.mobile-tab-bar") do
        expect(page).to have_link(I18n.t("layout.read_link"))
        expect(page).to have_content(I18n.t("layout.study_menu"))
        expect(page).to have_css("button[aria-label='#{I18n.t("layout.open_explore_menu")}']")
        expect(page).to have_content(I18n.t("layout.you_tab"))
      end
    end

    context "when signed in" do
      before { sign_in create(:user) }

      it "opens study links from the Study tab sheet" do
        visit "/"
        find("button[aria-label='#{I18n.t("layout.open_study_menu")}']").click

        within(".mobile-nav-sheet:not([hidden])") do
          expect(page).to have_link(I18n.t("layout.my_notes_link"))
          expect(page).to have_link(I18n.t("layout.my_studies_link"))
        end
      end
    end
  end
end
