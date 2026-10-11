require "rails_helper"

RSpec.describe Bible::Passages do
  after { described_class.reset! }

  describe "loading" do
    before do
      file = Tempfile.new([ "passages", ".yml" ])
      file.write(<<~YAML)
        - slug: sower
          kind: parable
          title_en: The Sower
          title_es: El sembrador
          appearances:
            - Matt.13.3-9
            - Mark.4.3-9
        - slug: light-of-the-world
          kind: word_picture
          title_en: The Light of the World
          title_es: La luz del mundo
          appearances:
            - John.8.12
      YAML
      file.close
      stub_const("Bible::Passages::CONFIG_PATH", Pathname.new(file.path))
      described_class.reset!
    end

    it "finds a passage by slug" do
      sower = described_class.find("sower")

      expect(sower.kind).to eq("parable")
      expect(described_class.find("nope")).to be_nil
    end

    it "titles a passage in the current locale" do
      sower = described_class.find("sower")

      expect(sower.title).to eq("The Sower")
      I18n.with_locale(:es) { expect(sower.title).to eq("El sembrador") }
    end

    it "parses each appearance into book, chapter and verse range" do
      first, second = described_class.find("sower").appearances

      expect([ first.book, first.chapter, first.verses ]).to eq([ "Matt", 13, 3..9 ])
      expect([ second.book, second.chapter, second.verses ]).to eq([ "Mark", 4, 3..9 ])
    end

    it "reads a single verse as a one-verse range" do
      appearance = described_class.find("light-of-the-world").appearances.first

      expect(appearance.verses).to eq(12..12)
    end

    it "carries a passage's themes, none by default" do
      expect(described_class.find("sower").themes).to eq([])
    end

    it "lists passages of one kind, in file order" do
      expect(described_class.of_kind("parable").map(&:slug)).to eq([ "sower" ])
      expect(described_class.of_kind("word_picture").map(&:slug)).to eq([ "light-of-the-world" ])
    end

    it "groups kinds into the lists the site presents" do
      expect(described_class.in_collection("parables").map(&:slug)).to eq(%w[sower light-of-the-world])
      expect(described_class.in_collection("encounters")).to be_empty
      expect(described_class.collection_of(described_class.find("light-of-the-world"))).to eq("parables")
    end

    it "finds the passages that begin in a chapter, by starting verse" do
      expect(described_class.starting_in("Matt", 13).transform_values(&:slug)).to eq(3 => "sower")
      expect(described_class.starting_in("Matt", 14)).to be_empty
    end

    it "gives the verse refs of an appearance in a translation" do
      appearance = described_class.find("light-of-the-world").appearances.first

      expect(appearance.osis_refs("RV1909")).to eq([ "Bible.RV1909.John.8.12" ])
    end
  end

  describe "config/passages.yml" do
    let(:passages) { described_class.all }

    it "gives every passage a unique, url-safe slug" do
      slugs = passages.map(&:slug)

      expect(slugs).to all(match(/\A[a-z0-9]+(-[a-z0-9]+)*\z/))
      expect(slugs.uniq).to eq(slugs)
    end

    it "uses only known kinds" do
      expect(passages.map(&:kind).uniq - described_class::KINDS).to be_empty
    end

    it "titles every passage in English and Spanish" do
      passages.each do |passage|
        expect(passage.title_en).to be_present, "#{passage.slug}: no English title"
        expect(passage.title_es).to be_present, "#{passage.slug}: no Spanish title"
      end
    end

    it "places every appearance in a canonical book, inside one chapter" do
      books = Bible::CanonicalBooks.osis_codes

      passages.each do |passage|
        expect(passage.appearances).to be_present, "#{passage.slug}: no appearances"
        passage.appearances.each do |appearance|
          expect(books).to include(appearance.book), "#{passage.slug}: unknown book #{appearance.book}"
          expect(appearance.chapter).to be_positive
          expect(appearance.verses.first).to be_between(1, appearance.verses.last)
        end
      end
    end

    it "tags passages only with themes that exist" do
      known = Bible::Themes.all.map(&:slug)

      passages.each do |passage|
        expect(passage.themes - known).to be_empty, "#{passage.slug}: unknown theme"
      end
    end

    it "includes encounters and sayings alongside the parables" do
      expect(described_class.of_kind("encounter")).to be_present
      expect(described_class.of_kind("saying")).to be_present
    end

    it "never lists the same gospel twice for one passage" do
      passages.each do |passage|
        books = passage.appearances.map(&:book)
        expect(books.uniq).to eq(books), "#{passage.slug}: repeated book"
      end
    end
  end
end
