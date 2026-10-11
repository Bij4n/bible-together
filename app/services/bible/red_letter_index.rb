module Bible
  # The chapters of a translation that contain any of Jesus's words, in
  # canon order. Drives navigation in the red reader, which steps from
  # one red chapter to the next and skips everything in between.
  class RedLetterIndex
    Entry = Struct.new(:book, :number) do
      def to_a = [ book, number ]
    end

    def self.for(translation)
      # Red-letter ranges only change when a translation is imported or
      # patched, so a short-lived cache is plenty.
      entries = Rails.cache.fetch([ "red_letter_index", translation.id ], expires_in: 1.hour) do
        Verse.joins(chapter: :book)
             .where(books: { translation_id: translation.id })
             .where("verses.red_letter_ranges <> '[]'::jsonb")
             .distinct
             .order("books.position", "chapters.number")
             .pluck("books.position", "books.osis_code", "chapters.number")
             .map { |_position, book, number| [ book, number ] }
      end
      new(entries.map { |book, number| Entry.new(book, number) })
    end

    attr_reader :chapters

    def initialize(chapters)
      @chapters = chapters
    end

    def first = chapters.first

    def include?(book, number)
      !position(book, number).nil?
    end

    def before(book, number)
      at = position(book, number)
      chapters[at - 1] if at&.positive?
    end

    def after(book, number)
      at = position(book, number)
      chapters[at + 1] if at
    end

    def books
      chapters.map(&:book).uniq
    end

    def chapters_in(book)
      chapters.select { |c| c.book == book }.map(&:number)
    end

    private

    def position(book, number)
      chapters.index { |c| c.book == book && c.number == number.to_i }
    end
  end
end
