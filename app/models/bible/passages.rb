module Bible
  # Loads the curated passages from config/passages.yml: the parables,
  # and the word pictures Jesus uses for himself in John. Like
  # CanonicalBooks, this is reference data that ships with the code, so
  # there is nothing to load into a database on deploy.
  #
  # A passage is told once per gospel at most. Each telling (an
  # "appearance") is written translation-free as Book.chapter.verses
  # and always sits inside a single chapter, because a highlight can't
  # span chapters and neither can a group's live-update stream.
  module Passages
    CONFIG_PATH = Rails.root.join("config", "passages.yml")
    KINDS = %w[parable word_picture].freeze

    Appearance = Struct.new(:book, :chapter, :verses) do
      # "Matt.13.3-9" or, for a single verse, "John.8.12".
      def self.parse(ref)
        book, chapter, verses = ref.split(".")
        first, last = verses.split("-").map(&:to_i)
        new(book, chapter.to_i, first..(last || first))
      end

      def osis_refs(translation_code)
        verses.map { |verse| "Bible.#{translation_code}.#{book}.#{chapter}.#{verse}" }
      end
    end

    Passage = Struct.new(:slug, :kind, :title_en, :title_es, :appearances, keyword_init: true) do
      def title
        I18n.locale == :es ? title_es : title_en
      end
    end

    class << self
      def all
        @all ||= YAML.safe_load_file(CONFIG_PATH).map do |entry|
          Passage.new(slug: entry["slug"], kind: entry["kind"],
                      title_en: entry["title_en"], title_es: entry["title_es"],
                      appearances: Array(entry["appearances"]).map { |ref| Appearance.parse(ref) })
        end
      end

      def find(slug)
        all.detect { |passage| passage.slug == slug }
      end

      def of_kind(kind)
        all.select { |passage| passage.kind == kind.to_s }
      end

      def reset!
        @all = nil
      end
    end
  end
end
