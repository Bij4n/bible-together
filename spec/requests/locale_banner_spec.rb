require "rails_helper"

RSpec.describe "Locale banner", type: :request do
  let!(:kjv) { create(:translation, :kjv) }
  let!(:rv1909) { create(:translation, code: "RV1909", name: "Reina-Valera 1909", language: "es") }

  let!(:kjv_book) { create(:book, :john, translation: kjv) }
  let!(:kjv_chapter) { create(:chapter, book: kjv_book, number: 3) }
  let!(:kjv_verse) do
    create(:verse, chapter: kjv_chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.John.3.16")
  end

  let!(:rv_book) { create(:book, :john, translation: rv1909) }
  let!(:rv_chapter) { create(:chapter, book: rv_book, number: 3) }
  let!(:rv_verse) do
    create(:verse, chapter: rv_chapter, number: 16,
                   body_text: "Porque de tal manera amó Dios al mundo",
                   body_html: "Porque de tal manera amó Dios al mundo",
                   red_letter_ranges: [],
                   osis_ref: "Bible.RV1909.John.3.16")
  end

  describe "visibility on the public reader" do
    it "renders the banner when UI locale differs from the translation's language" do
      get "/bible/kjv/john/3?locale=es"
      expect(response.body).to include(%(action="/locale_banner/dismiss))
      expect(response.body).to include("/bible/rv1909/john/3?layer=community")
    end

    it "hides the banner when UI locale matches the translation's language" do
      get "/bible/kjv/john/3"
      expect(response.body).not_to include(%(action="/locale_banner/dismiss))
    end

    it "hides the banner when no matching-language translation is installed" do
      rv1909.destroy
      get "/bible/kjv/john/3?locale=es"
      expect(response.body).not_to include(%(action="/locale_banner/dismiss))
    end
  end

  describe "visibility on the signed-in reader" do
    let(:user) { create(:user) }

    it "renders the banner for the same mismatch condition" do
      user.update!(ui_locale: "es")
      sign_in user
      get "/bible/kjv/john/3"
      expect(response.body).to include(%(action="/locale_banner/dismiss))
      expect(response.body).to include("/bible/rv1909/john/3")
    end
  end

  describe "visibility on non-reader pages" do
    it "never renders on the home page" do
      get "/?locale=es"
      expect(response.body).not_to include(%(action="/locale_banner/dismiss))
    end

    it "never renders on search" do
      get "/search?locale=es"
      expect(response.body).not_to include(%(action="/locale_banner/dismiss))
    end
  end

  describe "dismissal" do
    it "POST /locale_banner/dismiss sets a persistent cookie and redirects back" do
      post "/locale_banner/dismiss", headers: { "HTTP_REFERER" => "/public/bible/kjv/john/3?locale=es" }
      expect(response).to redirect_to("/public/bible/kjv/john/3?locale=es")
      expect(cookies["locale_banner_dismissed"]).to be_present
    end

    it "hides the banner after dismissal" do
      post "/locale_banner/dismiss", headers: { "HTTP_REFERER" => "/public/bible/kjv/john/3?locale=es" }
      get "/bible/kjv/john/3?locale=es"
      expect(response.body).not_to include(%(action="/locale_banner/dismiss))
    end

    it "falls back to root when there is no referrer" do
      post "/locale_banner/dismiss"
      expect(response).to redirect_to(root_path)
    end
  end
end
