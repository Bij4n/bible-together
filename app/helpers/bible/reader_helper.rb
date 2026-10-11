module Bible
  module ReaderHelper
    GOSPELS = %w[Matt Mark Luke John].freeze

    # Chapter URL under whichever lens the page is in, so the reader's
    # pickers and links keep a reader in Highlighted in Red.
    def reader_chapter_path(**args)
      @lens == :red ? red_chapter_path(**args) : bible_chapter_path(**args)
    end

    # The chapter numbers the chapter picker offers for a book.
    def reader_chapter_numbers(book)
      return @red_index.chapters_in(book.osis_code) if @lens == :red

      book.chapters.order(:number).pluck(:number)
    end

    # [previous, next] as path params ({ book:, chapter: }) or nil at
    # either end. Under the red lens these skip chapters with no red.
    def reader_neighbours(chapter)
      stops =
        if @lens == :red
          code = chapter.book.osis_code
          [ @red_index.before(code, chapter.number), @red_index.after(code, chapter.number) ]
            .map { |stop| stop && [ stop.book, stop.number ] }
        else
          [ chapter.previous, chapter.next ].map { |c| c && [ c.book.osis_code, c.number ] }
        end
      stops.map { |book, number| book && { book: book.downcase, chapter: number } }
    end

    # Books for the book picker as [heading, books] groups: the two
    # testaments, or under the red lens the gospels and everything
    # after them.
    def reader_book_groups(translation)
      if @lens == :red
        books = translation.books.where(osis_code: @red_index.books).order(:position).to_a
        gospels, later = books.partition { |b| GOSPELS.include?(b.osis_code) }
        [ [ t("bible.reader.red.gospels"), gospels ], [ t("bible.reader.red.after_resurrection"), later ] ]
      else
        [ [ t("bible.reader.old_testament"), translation.books.where(testament: :old).order(:position) ],
          [ t("bible.reader.new_testament"), translation.books.where(testament: :new).order(:position) ] ]
      end
    end

    def reader_first_chapter(book)
      @lens == :red ? @red_index.chapters_in(book.osis_code).first : 1
    end

    # "Luke 15:11–32", or "John 8:12" for a single verse, with the book
    # named in the current locale.
    def passage_reference(appearance)
      book = Bible::CanonicalBooks.find(appearance.book)
      name = I18n.locale == :es ? book[:name_es] : book[:name_en]
      verses = [ appearance.verses.first, appearance.verses.last ].uniq.join("–")
      "#{name} #{appearance.chapter}:#{verses}"
    end

    # A passage's page, optionally at one gospel's telling. The first
    # telling is the bare URL; a chosen translation is carried along.
    def passage_path(passage, appearance = nil)
      told_in = appearance&.book&.downcase
      told_in = nil if told_in == passage.appearances.first.book.downcase
      red_passage_path(collection: Bible::Passages.collection_of(passage), slug: passage.slug,
                       in: told_in, translation: params[:translation].presence)
    end

    # [previous, next] passage within the passage's own list.
    def passage_neighbours(passage)
      list = Bible::Passages.in_collection(Bible::Passages.collection_of(passage))
      at = list.index(passage)
      [ (list[at - 1] if at.positive?), list[at + 1] ]
    end

    # A passage on a study's list, read in the study's reader.
    def study_passage_path(group, passage, appearance = nil)
      told_in = appearance&.book&.downcase
      told_in = nil if told_in == passage.appearances.first.book.downcase
      group_passage_path(group, passage.slug, in: told_in, translation: params[:translation].presence)
    end

    # [previous, next] passage on the study's own list.
    def study_passage_neighbours(group, passage)
      list = group.passages
      at = list.index(passage)
      [ (list[at - 1] if at.positive?), list[at + 1] ]
    end

    # "The Parables", "Encounters", or a theme's name.
    def study_reading_list_title(group)
      list = group.reading_list
      return Bible::Themes.find(list.delete_prefix(Group::THEME_PREFIX)).name if list.start_with?(Group::THEME_PREFIX)

      t("red.#{list}.title")
    end

    # Whether the page dims narration. An encounter is the exception
    # under the red lens: there the story is the point, so it is shown
    # at full strength with his words still in red.
    def red_lens_dimmed?
      @lens == :red && @passage&.kind != "encounter"
    end

    # Curated passages that begin in the chapter on screen, keyed by
    # starting verse. Only the red chapter view marks them.
    def passage_markers
      return {} unless @lens == :red && @passage.nil?

      Bible::Passages.starting_in(@book.osis_code, @chapter.number)
    end

    # Verse id => ordered unique note ids, for the per-verse note chips
    # (design v3). Built from the chapter's already-loaded highlights
    # (notes eager-loaded by every reader controller), so the only extra
    # queries are the per-highlight affected_verses lookups — a handful
    # per chapter at most.
    def verse_note_map(highlights)
      map = Hash.new { |h, k| h[k] = { ids: [], color: nil, label: nil } }
      Array(highlights).each do |hl|
        hl.notes.each do |note|
          note_ids = [ note.id ]
          next if note_ids.empty?

          hl.affected_verses.each do |v|
            entry = map[v.id]
            entry[:ids].concat(note_ids)
            entry[:ids].uniq!
            entry[:color] ||= note.color
            entry[:label] ||= note.label.presence
          end
        end
      end
      map
    end

    # Emit verse HTML with highlight overlays layered over red-letter
    # (jesus-words) spans. Character ranges are merged via an event-list
    # sweep: collect every range boundary, sort, emit one span per
    # fragment between consecutive boundaries with the classes that are
    # active at that fragment.
    #
    # Overlap rules:
    #   - Jesus-words is always applied when active (orthogonal to
    #     highlights). A highlight over red letters shows both.
    #   - When multiple highlights cover the same character, the
    #     highest-id (most recent) highlight's color wins; all touching
    #     highlight ids are listed in data-highlight-ids for click
    #     disambiguation.
    # style: :fill (default) paints highlight fragments with the
    # owner's color overlay — your own marks. :underline renders them
    # as a quiet dotted underline instead (design v3 / Kindle rule:
    # other people's highlights are never louder than your own) — used
    # by the community layer.
    def render_verse_with_highlights(verse, highlights, style: :fill)
      text = verse.body_text.to_s
      return "".html_safe if text.empty?

      jesus_ranges     = Array(verse.red_letter_ranges)
      highlight_ranges = Array(highlights)
                         .filter_map { |h| verse_range_for(h, verse) }

      boundaries = Set.new([ 0, text.length ])
      jesus_ranges.each { |s, e| boundaries << s; boundaries << e }
      highlight_ranges.each { |r| boundaries << r[:start]; boundaries << r[:end] }
      sorted = boundaries.to_a.sort

      out = +""
      sorted.each_cons(2) do |from, to|
        next if from == to

        in_jesus = jesus_ranges.any? { |s, e| s <= from && from < e }
        active_highlights = highlight_ranges.select { |r| r[:start] <= from && from < r[:end] }

        fragment = ERB::Util.html_escape(text[from...to])

        if !in_jesus && active_highlights.empty?
          out << fragment
          next
        end

        classes = []
        classes << "jesus-words" if in_jesus

        if active_highlights.any?
          sorted_highlights = active_highlights.sort_by { |r| r[:id] }
          dominant = sorted_highlights.last
          classes << (style == :underline ? "community-highlight" : "highlight-#{dominant[:color]}")
          ids = sorted_highlights.map { |r| r[:id] }.join(",")
          # data-note-count is the dominant highlight's note count.
          # Drives the Sprint 16.5 PR C color-toggle removal flow:
          # 0 → instant remove on click, ≥1 → confirm dialog with
          # the count-aware bilingual message. The reader controller
          # eager-loads :notes on highlights so .size is in-memory.
          attrs = %(data-highlight-ids="#{ids}" data-note-count="#{dominant[:note_count]}")
          if style == :underline
            author_count = sorted_highlights.map { |r| r[:user_id] }.uniq.size
            label = ERB::Util.html_escape(t("public_bible.people_highlighted", count: author_count))
            attrs += %( title="#{label}" aria-label="#{label}")
          end
          out << %(<span class="#{classes.join(" ")}" #{attrs}>#{fragment}</span>)
        else
          out << %(<span class="#{classes.join(" ")}">#{fragment}</span>)
        end
      end

      out.html_safe
    end

    private

    # Projects a highlight's OsisRef onto a specific verse and returns
    # { id:, color:, start:, end: } in that verse's body_text coordinate
    # space. Returns nil when the highlight doesn't intersect this verse.
    def verse_range_for(highlight, verse)
      ref = highlight.parsed_ref
      return nil unless ref.start_chapter == verse.chapter.number
      return nil unless (ref.start_verse..ref.end_verse).cover?(verse.number)

      text_len = verse.body_text.to_s.length
      start_off = verse.number == ref.start_verse ? (ref.start_offset || 0) : 0
      end_off   = verse.number == ref.end_verse   ? resolve_end_offset(ref.end_offset, text_len) : text_len

      return nil if start_off >= end_off

      { id: highlight.id, color: highlight.color, start: start_off, end: end_off,
        note_count: highlight.notes.size, user_id: highlight.user_id }
    end

    def resolve_end_offset(offset, text_len)
      case offset
      when nil, OsisRef::END_OFFSET then text_len
      else offset.to_i
      end
    end
  end
end
