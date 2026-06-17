module VerseHighlightStreams
  extend ActiveSupport::Concern
  include Bible::ReaderHelper

  private

  def verse_replace_streams(verses)
    chapters = verses.map(&:chapter).uniq
    chapter_locals_cache = chapters.each_with_object({}) do |chapter, acc|
      prefix = "Bible.#{chapter.book.translation.code}.#{chapter.book.osis_code}.#{chapter.number}."
      cross_map = current_user.highlights.from_other_translations_in_chapter(
        translation_code: chapter.book.translation.code,
        book:             chapter.book.osis_code,
        chapter:          chapter.number
      ).each_with_object({}) do |h, m|
        h.affected_verses.each { |v| m[v.number] ||= h.translation.code }
      end
      acc[chapter.id] = {
        highlights: current_user.highlights.includes(:notes).for_chapter(prefix).to_a,
        cross_translation_highlights: cross_map
      }
    end

    chip_map_for = ->(ctx) { verse_note_map(ctx[:highlights]) }

    verses.map do |verse|
      ctx = chapter_locals_cache[verse.chapter.id]
      meta = chip_map_for.call(ctx)[verse.id]
      note_chip = if meta[:ids].any?
        { count: meta[:ids].size, href: edit_note_path(meta[:ids].first), turbo_frame: "note_panel",
          color: meta[:color], label: meta[:label] }
      end
      turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(verse),
        partial: "bible/reader/verse",
        locals: {
          verse: verse,
          highlights: ctx[:highlights],
          cross_translation_highlights: ctx[:cross_translation_highlights],
          chapter_opener: false,
          note_chip: note_chip
        }
      )
    end
  end
end
