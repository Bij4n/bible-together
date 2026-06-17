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

  it "shares the social-platform vision and that one person (a businessperson and developer) builds it" do
    get "/about"
    expect(response.body).to include(I18n.t("home.about.vision_label"))
    expect(response.body).to include(I18n.t("home.about.para_vision"))
    expect(response.body).to include(I18n.t("home.about.team_label"))
    expect(response.body).to include(I18n.t("home.about.para_team"))
  end

  it "no longer shows the removed reflective blockquote" do
    get "/about"
    expect(response.body).not_to include("the whole point")
    expect(response.body).not_to include("stopped someone else")
  end
end
