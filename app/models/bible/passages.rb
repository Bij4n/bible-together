module Bible
  # Loads the curated passages from config/passages.yml: the parables,
  # the word pictures Jesus uses for himself in John, his encounters
  # with people, and sayings that stand on their own. Like
  # CanonicalBooks, this is reference data that ships with the code, so
  # there is nothing to load into a database on deploy.
  #
  # A passage is told once per gospel at most. Each telling (an
  # "appearance") is written translation-free as Book.chapter.verses
  # and always sits inside a single chapter, because a highlight can't
  # span chapters and neither can a group's live-update stream.
  module Passages
    CONFIG_PATH = Rails.root.join("config", "passages.yml")
    KINDS = %w[parable word_picture encounter saying].freeze

    # The lists the site presents, and the kinds each one holds. John's
    # word pictures sit with the parables.
    COLLECTIONS = {
      "parables"   => %w[parable word_picture],
      "encounters" => %w[encounter],
      "sayings"    => %w[saying]
    }.freeze

    # explained is the verse range, later in the same chapter, where
    # Jesus explains the passage himself (the Sower, the Weeds). nil
    # for nearly every telling.
    Appearance = Struct.new(:book, :chapter, :verses, :explained) do
      # "Matt.13.3-9" or, for a single verse, "John.8.12".
      def self.parse(ref)
        book, chapter, verses = ref.split(".")
        first, last = verses.split("-").map(&:to_i)
        new(book, chapter.to_i, first..(last || first))
      end

      # Every verse the telling's page shows: the telling, then his
      # explanation when there is one.
      def verse_numbers
        verses.to_a + explained.to_a
      end

      def osis_refs(translation_code)
        verses.map { |verse| "Bible.#{translation_code}.#{book}.#{chapter}.#{verse}" }
      end
    end

    Passage = Struct.new(:slug, :kind, :title_en, :title_es, :appearances, :themes, keyword_init: true) do
      def title
        I18n.locale == :es ? title_es : title_en
      end
    end

    class << self
      def all
        @all ||= YAML.safe_load_file(CONFIG_PATH).map do |entry|
          Passage.new(slug: entry["slug"], kind: entry["kind"],
                      title_en: entry["title_en"], title_es: entry["title_es"],
                      appearances: appearances_from(entry),
                      themes: Array(entry["themes"]))
        end
      end

      def appearances_from(entry)
        explanations = Array(entry["explained"]).map { |ref| Appearance.parse(ref) }
        Array(entry["appearances"]).map do |ref|
          telling = Appearance.parse(ref)
          telling.explained = explanations.detect { |e| e.book == telling.book && e.chapter == telling.chapter }&.verses
          telling
        end
      end

      def find(slug)
        all.detect { |passage| passage.slug == slug }
      end

      def of_kind(kind)
        all.select { |passage| passage.kind == kind.to_s }
      end

      def in_collection(name)
        kinds = COLLECTIONS.fetch(name.to_s)
        all.select { |passage| kinds.include?(passage.kind) }
      end

      def collection_of(passage)
        COLLECTIONS.detect { |_name, kinds| kinds.include?(passage.kind) }&.first
      end

      # Passages with a telling that begins in this chapter, keyed by
      # the verse it begins at.
      def starting_in(book, chapter)
        all.each_with_object({}) do |passage, starts|
          passage.appearances.each do |appearance|
            next unless appearance.book == book && appearance.chapter == chapter

            starts[appearance.verses.first] ||= passage
          end
        end
      end

      def reset!
        @all = nil
      end
    end
  end
end
