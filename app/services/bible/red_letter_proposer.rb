module Bible
  # Proposes where Jesus's words fall in a verse of one translation,
  # given where they fall in the same verse of another. Character
  # offsets don't carry across languages, so this works from the shape
  # of the source ranges and the punctuation of the target:
  #
  #   - a range that starts mid-verse starts after a colon in the
  #     target ("Y Jesús le dijo: Hoy ha venido la salvación...")
  #   - a range that stops mid-verse stops at a sentence break
  #
  # When the target offers more than one such place, the one closest
  # to the source's relative position wins.
  #
  # The result is a proposal for a person to review, not data to write
  # blind. `confident?` is true only for the unambiguous shape: one
  # range, a single possible start, red through the end of the verse.
  # Reviewed output lives in config/red_letter/ and is applied by
  # Bible::RedLetterPatch.
  class RedLetterProposer
    Result = Struct.new(:ranges, :confident, keyword_init: true) do
      def confident? = confident
    end

    # Some source ranges stop just short of the verse's final
    # punctuation. That is still the whole verse.
    END_SLACK = 1

    def self.call(source_text:, source_ranges:, target_text:)
      new(source_text, source_ranges, target_text).call
    end

    def initialize(source_text, source_ranges, target_text)
      @source_text   = source_text
      @source_ranges = source_ranges
      @target_text   = target_text
    end

    def call
      ambiguous = @source_ranges.size > 1
      ranges = @source_ranges.map do |from, to|
        start, start_sure = map_start(from)
        return Result.new(ranges: nil, confident: false) if start.nil?

        finish, finish_sure = map_finish(to)
        ambiguous ||= !(start_sure && finish_sure)
        [ start, finish ]
      end

      return Result.new(ranges: nil, confident: false) unless well_formed?(ranges)

      Result.new(ranges: ranges, confident: !ambiguous)
    end

    private

    def map_start(from)
      return [ 0, true ] if from.zero?

      candidates = starts_after_colon
      [ nearest(candidates, from), candidates.size == 1 ]
    end

    def map_finish(to)
      return [ @target_text.length, true ] if to >= @source_text.length - END_SLACK

      [ nearest(sentence_ends, to), false ]
    end

    # Offsets of the first character of whatever follows each colon.
    def starts_after_colon
      offsets = []
      @target_text.scan(/:\s*/) { offsets << Regexp.last_match.end(0) }
      offsets.reject { |o| o >= @target_text.length }
    end

    # Offsets just past each sentence-ending mark, plus the verse end.
    def sentence_ends
      offsets = []
      @target_text.scan(/[.?!](?=\s|\z)/) { offsets << Regexp.last_match.end(0) }
      (offsets << @target_text.length).uniq
    end

    def nearest(candidates, source_offset)
      wanted = source_offset.to_f / @source_text.length
      candidates.min_by { |c| (c.to_f / @target_text.length - wanted).abs }
    end

    def well_formed?(ranges)
      ranges.all? { |s, e| s < e } && ranges.each_cons(2).all? { |a, b| a[1] <= b[0] }
    end
  end
end
