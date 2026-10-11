require "rails_helper"

RSpec.describe "About page", type: :request do
  it "renders the About content at /about" do
    get "/about"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("home.about.heading"))
    expect(response.body).to include(I18n.t("home.about.subhead"))
    expect(response.body).to include(I18n.t("home.about.para_1"))
    expect(response.body).to include(I18n.t("home.about.translations_label"))
  end

  it "renders the Spanish content with locale=es" do
    get "/about?locale=es"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("home.about.heading", locale: :es))
    expect(response.body).to include(I18n.t("home.about.para_1", locale: :es))
  end

  it "is reachable without authentication" do
    get "/about"
    expect(response).to have_http_status(:ok)
  end

  it "states it is a non-profit funded by donations" do
    get "/about"
    expect(response.body).to include(I18n.t("home.about.nonprofit_label"))
    expect(response.body).to include(I18n.t("home.about.para_nonprofit"))
  end

  it "says why the site exists and what we owe each other" do
    get "/about"
    expect(response.body).to include(I18n.t("home.about.vision_label"))
    expect(response.body).to include(I18n.t("home.about.para_why_1"))
    expect(response.body).to include(I18n.t("home.about.para_why_2"))
    expect(response.body).to include(I18n.t("home.about.duty_label"))
    expect(response.body).to include(I18n.t("home.about.para_duty"))
  end

  it "quotes Jesus, each quote linking to where he says it" do
    get "/about"

    page = Nokogiri::HTML(response.body)
    quotes = page.css(".about-quotes li")
    expect(quotes.size).to eq(5)
    expect(quotes.first.text).to include("Thou shalt love thy neighbour as thyself.")
    expect(quotes.map { |q| q.at_css("a")[:href] }).to eq(%w[
      /red/kjv/mark/12 /red/kjv/matt/25 /red/kjv/matt/9 /red/kjv/matt/23 /red/kjv/john/13
    ])
  end

  it "quotes him from the Reina-Valera in Spanish" do
    get "/about?locale=es"

    page = Nokogiri::HTML(response.body)
    expect(page.css(".about-quotes li").first.text).to include("Amarás á tu prójimo como á ti mismo.")
    expect(page.css(".about-quotes li a").first[:href]).to start_with("/red/rv1909/mark/12")
    expect(response.body).not_to include("translation missing")
  end

  it "tells the founder's story briefly, in the first person" do
    get "/about"
    expect(response.body).to include(I18n.t("home.about.team_label"))
    expect(response.body).to include(I18n.t("home.about.para_team"))
    expect(I18n.t("home.about.para_team")).to start_with("I was raised Muslim.")
  end

  it "no longer carries the old social-platform pitch" do
    get "/about"
    expect(response.body).not_to include("social platform")
    expect(response.body).not_to include("wearing every hat")
  end

  it "no longer shows the removed reflective blockquote" do
    get "/about"
    expect(response.body).not_to include("the whole point")
    expect(response.body).not_to include("stopped someone else")
  end
end
