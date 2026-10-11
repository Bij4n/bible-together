module Bible
  # Applies reviewed red-letter text from config/red_letter/<code>.yml
  # to a translation whose source didn't mark Jesus's words.
  #
  # Bible::RedLetterMirror covers verses that are red from end to end.
  # This covers the rest: verses where he speaks for only part of the
  # verse, which can't be copied by offset from another language.
  #
  # The file maps a verse to the passages in it that are his words,
  # quoted exactly:
  #
  #   John.8.11:
  #     - "Ni yo te condeno: vete, y no peques más."
  #
  # Storing the words rather than offsets keeps the file reviewable by
  # anyone who can read the language, and makes a drifted source text
  # impossible to miss: every passage must be found in its verse or
  # nothing at all is written.
  class RedLetterPatch
    class Mismatch < StandardError; end

    Result = Struct.new(:updated, keyword_init: true) do
      def to_s = "marked #{updated} verses"
    end

    class << self
      def call(translation_code:, path: nil)
        new(translation_code, path || path_for(translation_code)).call
      end

      def exists_for?(translation_code)
        path_for(translation_code).present?
      end

      # Tests also see spec/fixtures/red_letter so fixture-only patches
      # never sit beside real ones.
      def path_for(translation_code)
        dirs = [ Rails.root.join("config/red_letter") ]
        dirs << Rails.root.join("spec/fixtures/red_letter") if Rails.env.test?
        dirs.map { |dir| dir.join("#{translation_code.to_s.downcase}.yml") }.detect(&:exist?)
      end
    end

    def initialize(translation_code, path)
      @code = translation_code.to_s.upcase
      @path = path
    end

    def call
      raise Mismatch, "no red-letter patch for #{@code}" if @path.nil?

      entries = YAML.safe_load_file(@path) || {}
      verses  = Verse.where(osis_ref: entries.keys.map { |ref| osis_ref(ref) }).index_by(&:osis_ref)

      problems = []
      planned = entries.filter_map do |ref, passages|
        verse = verses[osis_ref(ref)]
        ranges = verse && locate(verse.body_text, Array(passages))
        next [ verse, ranges ] if ranges

        problems << (verse ? "#{ref}: text not found in verse" : "#{ref}: no such verse")
        nil
      end
      raise Mismatch, "#{@code} red-letter patch does not match:\n  #{problems.join("\n  ")}" if problems.any?

      Verse.transaction do
        planned.each do |verse, ranges|
          verse.update_columns(red_letter_ranges: ranges, red_text: Verse.red_text_for(verse.body_text, ranges))
        end
      end

      Result.new(updated: planned.size)
    end

    private

    def osis_ref(ref)
      "Bible.#{@code}.#{ref}"
    end

    # Finds each passage in order, each one after the last. Returns nil
    # if any is absent.
    def locate(text, passages)
      cursor = 0
      ranges = passages.map do |passage|
        start = text.index(passage, cursor)
        return nil if start.nil? || passage.empty?

        cursor = start + passage.length
        [ start, cursor ]
      end
      ranges.presence
    end
  end
end
