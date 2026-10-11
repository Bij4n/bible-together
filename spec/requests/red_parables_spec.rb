require "rails_helper"

RSpec.describe "Highlighted in Red parables", type: :request do
  let!(:kjv)    { create(:translation, :kjv) }
  let!(:rv1909) { create(:translation, code: "RV1909", name: "Reina-Valera 1909", language: "es") }

  def book!(translation, code, en, es, position)
    create(:book, translation: translation, osis_code: code, name_en: en, name_es: es,
                  position: position, testament: :new)
  end

  def verse!(book, chapter_number, number, text, red: true)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ [ 0, text.length ] ] : [],
                   osis_ref: "Bible.#{book.translation.code}.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  let(:matthew) { book!(kjv, "Matt", "Matthew", "Mateo", 40) }
  let(:mark)    { book!(kjv, "Mark", "Mark", "Marcos", 41) }
  let(:mateo)   { book!(rv1909, "Matt", "Matthew", "Mateo", 40) }

  before do
    # The Sower: Matt.13.3-9 and Mark.4.3-9 (config/passages.yml).
    verse!(matthew, 13, 2, "And great multitudes were gathered together unto him.", red: false)
    (3..9).each { |n| verse!(matthew, 13, n, "Matthew sower verse #{n}.") }
    verse!(matthew, 13, 10, "And the disciples came, and said unto him.", red: false)
    (3..9).each { |n| verse!(mark, 4, n, "Mark sower verse #{n}.") }
    (3..9).each { |n| verse!(mateo, 13, n, "Mateo sembrador versículo #{n}.") }
  end

  describe "GET /red/parables" do
    it "lists the parables and John's word pictures with where each is told" do
      get "/red/parables"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Sower", "The Prodigal Son", "The Good Shepherd")
      expect(response.body).to include(%(href="/red/parables/sower"))
      expect(response.body).to include("Matthew 13:3–9", "Mark 4:3–9", "Luke 8:5–8")
      expect(response.body).to include(I18n.t("red.parables.word_pictures_heading"))
    end

    it "renders in Spanish" do
      get "/red/parables", params: { locale: "es" }

      expect(response.body).to include("El sembrador", "El hijo pródigo", "Mateo 13:3–9")
      expect(response.body).not_to include("translation missing")
    end
  end

  describe "GET /red/parables/:slug" do
    context "when signed in" do
      before { sign_in create(:user) }

      it "shows only the passage's verses, under the red lens" do
        get "/red/parables/sower"

        expect(response).to have_http_status(:ok)
        page = Nokogiri::HTML(response.body)
        expect(page.at_css("article")[:class].split).to include("red-lens")
        expect(page.at_css("h1").text).to include("The Sower")
        expect(page.css(".chapter-body .verse").map { |v| v["data-osis-ref"] })
          .to eq((3..9).map { |n| "Bible.KJV.Matt.13.#{n}" })
        expect(response.body).to include("Matthew 13:3–9")
      end

      it "shows his explanation under the parable, with a heading where it starts" do
        (18..23).each { |n| verse!(matthew, 13, n, "Matthew sower explained #{n}.") }

        get "/red/parables/sower"

        page = Nokogiri::HTML(response.body)
        expect(page.css(".chapter-body .verse").map { |v| v["data-osis-ref"].split(".").last.to_i })
          .to eq((3..9).to_a + (18..23).to_a)
        heading = page.at_css(".chapter-body .passage-explanation")
        expect(heading.text.squish).to eq(I18n.t("red.explained"))
        expect(heading.next_element["data-osis-ref"]).to eq("Bible.KJV.Matt.13.18")
      end

      it "shows no explanation heading for a telling that has none" do
        get "/red/parables/sower", params: { in: "mark" }

        expect(response.body).not_to include("passage-explanation")
      end

      it "offers the other gospels that tell it, and switches to one" do
        get "/red/parables/sower"
        expect(response.body).to include(%(href="/red/parables/sower?in=mark"))

        get "/red/parables/sower", params: { in: "mark" }
        expect(response.body).to include("Mark sower verse 3.")
        expect(response.body).not_to include("Matthew sower verse 3.")
      end

      it "leaves out a gospel the translation has no text for" do
        get "/red/parables/sower"

        expect(response.body).not_to include("in=luke")
      end

      it "reads in another translation" do
        get "/red/parables/sower", params: { translation: "rv1909" }

        expect(response.body).to include("Mateo sembrador versículo 3.")
      end

      it "links to the passage in its chapter and to the next parable" do
        get "/red/parables/sower"

        expect(response.body).to include(%(href="/red/kjv/matt/13#verse_))
        expect(response.body).to include(%(href="/red/parables/wheat-and-weeds"))
        expect(response.body).to include(%(href="/red/parables"))
      end

      it "keeps the reader able to highlight" do
        get "/red/parables/sower"

        expect(Nokogiri::HTML(response.body).at_css("article")["data-controller"]).to include("highlight")
      end

      it "404s on an unknown parable" do
        get "/red/parables/nope"

        expect(response).to have_http_status(:not_found)
      end

      it "404s on a gospel that does not tell it" do
        get "/red/parables/sower", params: { in: "john" }

        expect(response).to have_http_status(:not_found)
      end
    end

    it "serves signed-out visitors the read-only view" do
      get "/red/parables/sower"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Matthew sower verse 3.")
      expect(response.body).not_to include("Matthew 13:10")
    end

    it "defaults to Spanish scripture for a Spanish-language visitor" do
      get "/red/parables/sower", params: { locale: "es" }

      expect(response.body).to include("Mateo sembrador versículo 3.", "El sembrador")
    end

    it "shows only community notes that touch the passage" do
      inside  = public_note_on("Bible.KJV.Matt.13.4", "On the wayside seed")
      outside = public_note_on("Bible.KJV.Matt.13.10", "On the disciples' question")

      get "/red/parables/sower"

      expect(response.body).to include("On the wayside seed")
      expect(response.body).not_to include("On the disciples' question")
      expect([ inside, outside ]).to all(be_persisted)
    end
  end

  def public_note_on(osis_ref, body)
    user = create(:user)
    highlight = create(:highlight, user: user, translation: kjv, osis_ref: osis_ref, color: "gold")
    note = create(:note, user: user, body: "<p>#{body}</p>", visibility: :public_note)
    create(:highlight_note, highlight: highlight, note: note)
    note
  end
end
