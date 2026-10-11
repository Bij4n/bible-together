require "rails_helper"
require "axe-rspec"

RSpec.describe "Highlighted in Red front page", type: :system, js: true do
  let!(:kjv) { create(:translation, :kjv) }

  before do
    matthew = create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo",
                            position: 40, testament: :new)
    chapter = create(:chapter, book: matthew, number: 4)
    create(:verse, chapter: chapter, number: 19, body_text: "Follow me.", body_html: "Follow me.",
                   red_letter_ranges: [ [ 0, 10 ] ], osis_ref: "Bible.KJV.Matt.4.19")
  end

  it "is reached from the site navigation and opens the red reader" do
    visit "/"
    within("header.site-header nav.site-nav") { click_on I18n.t("layout.red_link") }

    expect(page).to have_current_path("/red")
    expect(page).to have_css("h1", text: I18n.t("red.home.title"))

    within(".red-doors") { click_on I18n.t("red.home.doors.words.cta") }
    expect(page).to have_current_path("/red/kjv/matt/4")
    expect(page).to have_css("span.jesus-words", text: "Follow me.")
  end

  it "leads to the parables, the encounters and a theme" do
    visit "/red"
    within(".red-doors") { click_on I18n.t("red.home.doors.parables.cta") }
    expect(page).to have_current_path("/red/parables")

    visit "/red"
    within(".red-doors") { click_on I18n.t("red.home.doors.encounters.cta") }
    expect(page).to have_current_path("/red/encounters")

    visit "/red"
    within(".red-themes") { click_on "Forgiveness" }
    expect(page).to have_current_path("/red/themes/forgiveness")
  end

  it "is introduced on the homepage for visitors" do
    visit "/"
    within("[data-section='highlighted-in-red']") { click_on I18n.t("home.red.cta") }

    expect(page).to have_current_path("/red")
  end

  it "is offered on the dashboard for members" do
    sign_in create(:user)
    visit "/"
    within("[data-section='highlighted-in-red']") { click_on I18n.t("red.home.doors.encounters.title") }

    expect(page).to have_current_path("/red/encounters")
  end

  it "is reachable from the mobile tab bar" do
    at_window_size(390, 844) do
      visit "/"
      within("nav.mobile-tab-bar") { click_on I18n.t("layout.red_link") }

      expect(page).to have_current_path("/red")
    end
  end

  it "is axe-clean and fits a phone-width screen" do
    at_window_size(375, 800) do
      visit "/red"
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 1

      visit "/"
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 1

      sign_in create(:user)
      visit "/"
      expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa)
      expect(page.evaluate_script("document.documentElement.scrollWidth - window.innerWidth")).to be <= 1
    end
  end
end
