require "rails_helper"

RSpec.describe "Highlighted in Red reader", type: :request do
  let!(:kjv) { create(:translation, :kjv) }
  let(:genesis) { create(:book, translation: kjv, osis_code: "Gen", name_en: "Genesis", name_es: "Génesis", position: 1, testament: :old) }
  let(:matthew) { create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo", position: 40, testament: :new) }
  let(:john)    { create(:book, translation: kjv, osis_code: "John", name_en: "John", name_es: "Juan", position: 43, testament: :new) }
  let(:acts)    { create(:book, translation: kjv, osis_code: "Acts", name_en: "Acts", name_es: "Hechos", position: 44, testament: :new) }

  def verse!(book, chapter_number, number, text, red: nil)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.#{book.translation.code}.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    verse!(genesis, 1, 1, "In the beginning God created the heaven and the earth.")
    verse!(matthew, 4, 18, "And Jesus, walking by the sea of Galilee, saw two brethren.")
    verse!(matthew, 4, 19, "And he saith unto them, Follow me.", red: [ 24, 34 ])
    verse!(matthew, 5, 1, "And seeing the multitudes, he went up into a mountain.")
    verse!(john, 3, 16, "For God so loved the world.", red: [ 0, 27 ])
    verse!(acts, 9, 4, "Saul, Saul, why persecutest thou me?", red: [ 0, 36 ])
  end

  describe "GET /red" do
    it "sends the reader to the first chapter with red text" do
      get "/red"

      expect(response).to redirect_to("/red/kjv/matt/4")
    end
  end

  describe "GET /red/:translation/:book/:chapter" do
    context "when signed in" do
      before { sign_in create(:user) }

      it "renders the chapter under the red lens" do
        get "/red/kjv/matt/4"

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML(response.body).at_css("article")[:class].split).to include("red-lens")
        expect(response.body).to include(I18n.t("bible.reader.red.eyebrow"))
        expect(response.body).to include(%(<span class="jesus-words">Follow me.</span>))
      end

      it "marks verses with no red text as narration" do
        get "/red/kjv/matt/4"

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("[data-osis-ref='Bible.KJV.Matt.4.18']")[:class]).to include("verse-narration")
        expect(page.at_css("[data-osis-ref='Bible.KJV.Matt.4.19']")[:class]).not_to include("verse-narration")
      end

      it "steps over chapters that have no red text" do
        get "/red/kjv/matt/4"

        page = Nokogiri::HTML(response.body)
        expect(page.css("nav a").map { |a| a[:href] }).to include("/red/kjv/john/3")
        expect(response.body).not_to include("/red/kjv/matt/5")
      end

      it "offers only books and chapters that have red text" do
        get "/red/kjv/matt/4"

        urls = Nokogiri::HTML(response.body).css("button[data-url]").map { |b| b["data-url"] }
        expect(urls).to include("/red/kjv/john/3", "/red/kjv/acts/9")
        expect(urls.grep(/gen/)).to be_empty
        expect(response.body).to include(I18n.t("bible.reader.red.gospels"))
        expect(response.body).to include(I18n.t("bible.reader.red.after_resurrection"))
      end

      it "links back to the whole chapter" do
        get "/red/kjv/matt/4"

        expect(response.body).to include(%(href="/bible/kjv/matt/4"))
      end

      it "sends a chapter with no red text to the ordinary reader" do
        get "/red/kjv/gen/1"

        expect(response).to redirect_to("/bible/kjv/gen/1")
      end

      it "keeps the red lens when lowercasing the path" do
        get "/red/KJV/Matt/4"

        expect(response).to have_http_status(:moved_permanently)
        expect(response.location).to end_with("/red/kjv/matt/4")
      end

      it "renders in Spanish" do
        sign_in create(:user, ui_locale: "es")
        get "/red/kjv/matt/4"

        expect(response.body).to include(I18n.t("bible.reader.red.eyebrow", locale: :es))
        expect(response.body).not_to include("translation missing")
      end
    end

    it "serves signed-out visitors the read-only community view under the red lens" do
      get "/red/kjv/matt/4"

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css("article")[:class].split).to include("red-lens")
      expect(response.body).to include("/red/kjv/john/3")
    end
  end

  describe "the ordinary reader" do
    before { sign_in create(:user) }

    it "offers the red lens on a chapter that has red text" do
      get "/bible/kjv/matt/4"

      expect(response.body).to include(%(href="/red/kjv/matt/4"))
      expect(Nokogiri::HTML(response.body).at_css("article")[:class].split).not_to include("red-lens")
    end

    it "does not offer it on a chapter with none" do
      get "/bible/kjv/gen/1"

      expect(response.body).not_to include("/red/kjv/gen/1")
    end
  end
end
