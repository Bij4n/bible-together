require "rails_helper"

RSpec.describe "About page", type: :system do
  it "says why the site exists, in his words and ours" do
    visit "/about"

    expect(page).to have_content(/#{I18n.t("home.about.vision_label")}/i)
    expect(page).to have_content("He would be outside, with the people on the street.")
    within(".about-quotes") do
      expect(page).to have_content("Thou shalt love thy neighbour as thyself.")
      expect(page).to have_link("Mark 12:31", href: "/red/kjv/mark/12")
      expect(page).to have_link("John 13:35", href: "/red/kjv/john/13")
    end
    expect(page).to have_content("We are all brothers and sisters.")
    expect(page).to have_content("I was raised Muslim.")
  end
end
