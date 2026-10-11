require "rails_helper"

RSpec.describe "Highlighted in Red encounters, sayings and themes", type: :request do
  let!(:kjv) { create(:translation, :kjv) }

  def book!(code, en, es, position)
    create(:book, translation: kjv, osis_code: code, name_en: en, name_es: es, position: position, testament: :new)
  end

  def verse!(book, chapter_number, number, text, red: nil)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  let(:luke) { book!("Luke", "Luke", "Lucas", 42) }
  let(:john) { book!("John", "John", "Juan", 43) }
  let(:matthew) { book!("Matt", "Matthew", "Mateo", 40) }

  before do
    # Zacchaeus: Luke.19.1-10. The Ten Minas parable starts at Luke.19.11.
    verse!(luke, 19, 1, "And Jesus entered and passed through Jericho.")
    (2..8).each { |n| verse!(luke, 19, n, "Zacchaeus narration #{n}.") }
    verse!(luke, 19, 9, "And Jesus said unto him, This day is salvation come to this house.", red: [ 25, 66 ])
    verse!(luke, 19, 10, "For the Son of man is come to seek and to save that which was lost.", red: [ 0, 67 ])
    verse!(luke, 19, 11, "And as they heard these things, he added and spake a parable.")
    # The True Vine, last of the parables collection: John.15.1-8.
    (1..8).each { |n| verse!(john, 15, n, "Vine verse #{n}.", red: [ 0, 13 ]) }
    # Judge Not: Matt.7.1-5.
    (1..5).each { |n| verse!(matthew, 7, n, "Judge not verse #{n}.", red: [ 0, 18 ]) }
  end

  describe "the lists" do
    it "lists the encounters" do
      get "/red/encounters"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zacchaeus", "The Woman at the Well")
      expect(response.body).to include(%(href="/red/encounters/zacchaeus"))
      expect(response.body).not_to include("The Prodigal Son")
    end

    it "lists the sayings" do
      get "/red/sayings"

      expect(response.body).to include("The Beatitudes", %(href="/red/sayings/judge-not"))
      expect(response.body).not_to include("Zacchaeus")
    end

    it "renders both in Spanish" do
      get "/red/encounters", params: { locale: "es" }
      expect(response.body).to include("Zaqueo", I18n.t("red.encounters.title", locale: :es))
      expect(response.body).not_to include("translation missing")

      get "/red/sayings"
      expect(response.body).to include("Las bienaventuranzas")
      expect(response.body).not_to include("translation missing")
    end

    it "404s on a list that does not exist" do
      get "/red/miracles"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "an encounter" do
    it "shows the story at full strength, with his words still red" do
      get "/red/encounters/zacchaeus"

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css("h1").text).to include("Zacchaeus")
      expect(page.css(".chapter-body .verse").size).to eq(10)
      expect(page.at_css(".chapter-body")[:class]).to include("text-surface-900")
      expect(page.at_css("article")[:class].split).not_to include("red-lens")
      expect(response.body).not_to include(I18n.t("bible.reader.red.words_only"))
      expect(response.body).to include(%(<span class="jesus-words">This day is salvation come to this house.</span>))
    end

    it "links to its themes" do
      get "/red/encounters/zacchaeus"

      expect(response.body).to include(%(href="/red/themes/welcoming-outsiders"))
      expect(response.body).to include(%(href="/red/themes/forgiveness"))
    end

    it "moves a passage asked for under the wrong list to the right one" do
      get "/red/parables/zacchaeus"

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to end_with("/red/encounters/zacchaeus")
    end
  end

  describe "stepping through a list" do
    it "stops at the end of the list instead of running into the next kind" do
      get "/red/parables/true-vine"

      nav = Nokogiri::HTML(response.body).at_css(".passage-nav")
      expect(nav.css("a").map { |a| a[:href] }).to eq([ "/red/parables/way-truth-and-life" ])
    end

    it "steps between sayings" do
      get "/red/sayings/judge-not"

      hrefs = Nokogiri::HTML(response.body).at_css(".passage-nav").css("a").map { |a| a[:href] }
      expect(hrefs).to eq([ "/red/sayings/do-not-worry", "/red/sayings/golden-rule" ])
      expect(Nokogiri::HTML(response.body).at_css("article")[:class].split).to include("red-lens")
    end
  end

  describe "themes" do
    it "lists the themes" do
      get "/red/themes"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("He welcomes the outsider", %(href="/red/themes/forgiveness"))
    end

    it "sets what he did beside what he said and the stories he told" do
      get "/red/themes/forgiveness"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("red.themes.did"), I18n.t("red.themes.said"), I18n.t("red.themes.told"))
      expect(response.body).to include(%(href="/red/encounters/woman-caught-in-adultery"))
      expect(response.body).to include(%(href="/red/sayings/seventy-times-seven"))
      expect(response.body).to include(%(href="/red/parables/prodigal-son"))
      expect(response.body).not_to include("The Rich Fool")
    end

    it "renders a theme in Spanish" do
      get "/red/themes/forgiveness", params: { locale: "es" }

      expect(response.body).to include("El perdón", "El hijo pródigo")
      expect(response.body).not_to include("translation missing")
    end

    it "404s on an unknown theme" do
      get "/red/themes/nope"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "the red chapter view" do
    # The links carry the chapter's translation, so a reader in the
    # RV1909 stays in the RV1909.
    it "marks where a curated passage begins and links to it" do
      get "/red/kjv/luke/19"

      page = Nokogiri::HTML(response.body)
      markers = page.css(".chapter-body a.passage-marker").map { |a| [ a[:href], a.text.squish ] }
      expect(markers).to include([ "/red/encounters/zacchaeus?translation=kjv",
                                   "#{I18n.t('red.kinds.encounter')} · Zacchaeus" ])
      expect(markers.map(&:first)).to include("/red/parables/ten-minas?translation=kjv")
    end

    it "does not mark passages on a passage's own page or in the ordinary reader" do
      get "/red/encounters/zacchaeus"
      expect(response.body).not_to include("passage-marker")

      sign_in create(:user)
      get "/bible/kjv/luke/19"
      expect(response.body).not_to include("passage-marker")
    end
  end
end
