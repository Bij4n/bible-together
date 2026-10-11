require "rails_helper"

RSpec.describe "Highlighted in Red front page", type: :request do
  let!(:kjv) { create(:translation, :kjv) }

  before do
    matthew = create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo",
                            position: 40, testament: :new)
    chapter = create(:chapter, book: matthew, number: 4)
    create(:verse, chapter: chapter, number: 19, body_text: "Follow me.", body_html: "Follow me.",
                   red_letter_ranges: [ [ 0, 10 ] ], osis_ref: "Bible.KJV.Matt.4.19")
  end

  describe "GET /red" do
    it "offers the three doors, the sayings and every theme" do
      get "/red"

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      doors = page.css(".red-doors a").map { |a| a[:href] }
      expect(doors).to eq([ "/red/words", "/red/parables", "/red/encounters" ])
      expect(response.body).to include(%(href="/red/sayings"))
      expect(page.css(".red-themes a").map { |a| a[:href] })
        .to eq(Bible::Themes.all.map { |theme| "/red/themes/#{theme.slug}" })
      expect(page.at_css("h1").text).to include(I18n.t("red.home.title"))
    end

    it "says plainly that nothing is filtered or added" do
      get "/red"

      expect(response.body).to include(I18n.t("red.home.note"))
    end

    it "renders in Spanish" do
      get "/red", params: { locale: "es" }

      expect(response.body).to include(I18n.t("red.home.doors.words.title", locale: :es), "El perdón")
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "GET /red/words" do
    it "sends the reader to the first chapter with red text" do
      get "/red/words"

      expect(response).to redirect_to("/red/kjv/matt/4")
    end
  end

  describe "site navigation" do
    def nav_link(body, href)
      Nokogiri::HTML(body).at_css("header.site-header nav.site-nav a[href='#{href}']")
    end

    it "carries a Highlighted in Red link, active inside the section" do
      get "/red"

      link = nav_link(response.body, "/red")
      expect(link.text.squish).to eq(I18n.t("layout.red_link"))
      expect(link[:class]).to include("site-nav-link--active")
      expect(nav_link(response.body, "/bible")[:class]).not_to include("site-nav-link--active")
    end

    it "keeps Read active in the ordinary reader, and marks the red reader as the red section" do
      get "/bible/kjv/matt/4"
      expect(nav_link(response.body, "/bible")[:class]).to include("site-nav-link--active")
      expect(nav_link(response.body, "/red")[:class]).not_to include("site-nav-link--active")

      get "/red/kjv/matt/4"
      expect(nav_link(response.body, "/red")[:class]).to include("site-nav-link--active")
      expect(nav_link(response.body, "/bible")[:class]).not_to include("site-nav-link--active")
    end

    it "is in the mobile tab bar too" do
      get "/red"

      tab = Nokogiri::HTML(response.body).at_css("nav.mobile-tab-bar a[href='/red']")
      expect(tab.text.squish).to eq(I18n.t("layout.red_link"))
      expect(tab["aria-current"]).to eq("page")
    end
  end

  describe "entry points" do
    it "introduces the section on the homepage for visitors" do
      get "/"

      section = Nokogiri::HTML(response.body).at_css("[data-section='highlighted-in-red']")
      expect(section.text).to include(I18n.t("home.red.heading"))
      expect(section.css("a").map { |a| a[:href] }).to include("/red")
    end

    it "offers it on the dashboard for members" do
      sign_in create(:user)
      get "/"

      section = Nokogiri::HTML(response.body).at_css("[data-section='highlighted-in-red']")
      expect(section.css("a").map { |a| a[:href] }).to include("/red", "/red/parables", "/red/encounters")
    end
  end
end
