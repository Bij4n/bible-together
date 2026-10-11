require "rails_helper"

RSpec.describe "Legal pages", type: :request do
  %w[terms privacy].each do |page|
    describe "GET /#{page}" do
      it "renders without signing in, in both languages" do
        get "/#{page}"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("legal.#{page}.title"))

        get "/#{page}", params: { locale: "es" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("legal.#{page}.title", locale: :es))
        expect(response.body).not_to include("translation missing")
      end

      # Dark mode was removed in June 2026; the locale strings that
      # carry their own link markup were missed in that sweep.
      it "carries no dark-mode classes" do
        get "/#{page}"

        expect(response.body).not_to include("dark:")
      end
    end
  end
end
