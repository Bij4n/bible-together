require "rails_helper"

RSpec.describe "Homepage donate call to action", type: :request do
  before { create(:bitcoin_address, :active) }

  it "asks visitors to donate to the mission" do
    get "/"

    section = Nokogiri::HTML(response.body).at_css("[data-section='donate-cta']")
    expect(section.at_css("h2").text.squish).to eq("Donate to the Mission")
    expect(response.body).not_to include("Keep Bible Together free")
  end

  it "says the same in Spanish" do
    get "/", params: { locale: "es" }

    section = Nokogiri::HTML(response.body).at_css("[data-section='donate-cta']")
    expect(section.at_css("h2").text.squish).to eq("Dona a la misión")
  end
end
