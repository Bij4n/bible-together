module Bible
  # Loads the themes from config/themes.yml. A theme gathers the
  # passages tagged with it in config/passages.yml, so its page can set
  # what Jesus said beside what he did.
  module Themes
    CONFIG_PATH = Rails.root.join("config", "themes.yml")

    Theme = Struct.new(:slug, :name_en, :name_es, keyword_init: true) do
      def name
        I18n.locale == :es ? name_es : name_en
      end

      def passages
        Bible::Passages.all.select { |passage| passage.themes.include?(slug) }
      end
    end

    class << self
      def all
        @all ||= YAML.safe_load_file(CONFIG_PATH).map { |entry| Theme.new(**entry.symbolize_keys) }
      end

      def find(slug)
        all.detect { |theme| theme.slug == slug }
      end

      def reset!
        @all = nil
      end
    end
  end
end
