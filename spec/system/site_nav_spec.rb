require "rails_helper"

# Primary nav parity: desktop rail destinations must also appear in the
# mobile account sheet (which doubles as the mobile menu below sm).
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

  def open_mobile_menu
    find("button[data-user-menu-target='trigger']").click
    expect(page).to have_css("div[data-user-menu-target='menu']:not([hidden])")
  end

  it "labels the header nav for assistive tech" do
    visit "/"
    expect(page).to have_css("nav.site-nav[aria-label='#{I18n.t("layout.main_nav")}']")
  end

  context "when signed out" do
    it "mirrors desktop destinations in the mobile menu" do
      visit "/"
      open_mobile_menu

      within("div[data-user-menu-target='menu']") do
        expect(page).to have_link(I18n.t("layout.read_link"), visible: :all)
        expect(page).to have_link(I18n.t("layout.community_link"), visible: :all)
        expect(page).to have_link(I18n.t("layout.how_it_works_link"), visible: :all)
        expect(page).to have_link(I18n.t("search.submit"), visible: :all)
        expect(page).not_to have_link(I18n.t("layout.studies_link"), visible: :all)
      end
    end
  end

  context "when signed in" do
    before { sign_in create(:user) }

    it "mirrors desktop destinations in the mobile menu" do
      visit "/"
      open_mobile_menu

      within("div[data-user-menu-target='menu']") do
        expect(page).to have_link(I18n.t("layout.read_link"), visible: :all)
        expect(page).to have_link(I18n.t("layout.studies_link"), visible: :all)
        expect(page).to have_link(I18n.t("layout.community_link"), visible: :all)
        expect(page).to have_link(I18n.t("search.submit"), visible: :all)
        expect(page).not_to have_link(I18n.t("layout.how_it_works_link"), visible: :all)
      end
    end
  end
end
