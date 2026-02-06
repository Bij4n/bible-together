# Broadcast verse replacements and note-list mutations to the right
# GroupBibleChannel streams whenever a Highlight, Note, or NoteShare
# changes in a way that affects what group members see.
#
# Streams are keyed by [group, "bible", translation_code, book_osis,
# chapter_number] — same tuple the view passes to turbo_stream_from.
# Each member viewing that group's copy of that chapter gets the
# broadcast; non-members don't subscribe (channel rejects them).
module GroupBibleBroadcastable
  extend ActiveSupport::Concern

  def broadcast_verse_replace_to_groups(groups, verses)
    return if groups.empty? || verses.empty?

    groups.each do |group|
      verses.each do |verse|
        translation_code = verse.chapter.book.translation.code
        book_osis        = verse.chapter.book.osis_code
        chapter_number   = verse.chapter.number

        Turbo::StreamsChannel.broadcast_replace_to(
          group, "bible", translation_code, book_osis, chapter_number,
          target: ActionView::RecordIdentifier.dom_id(verse),
          partial: "bible/reader/verse",
          locals: {
            verse: verse,
            highlights: visible_highlights_for(verse, group)
          }
        )
      end
    end
  end

  def broadcast_note_append_to_groups(groups, note)
    groups.each do |group|
      target_chapters_for(note).each do |verse|
        Turbo::StreamsChannel.broadcast_append_to(
          group, "bible", verse[:translation], verse[:book], verse[:chapter],
          target: "group_notes_list",
          partial: "groups/bible/note",
          locals: { note: note }
        )
      end
    end
  end

  def broadcast_note_remove_to_groups(groups, note)
    groups.each do |group|
      target_chapters_for(note).each do |verse|
        Turbo::StreamsChannel.broadcast_remove_to(
          group, "bible", verse[:translation], verse[:book], verse[:chapter],
          target: ActionView::RecordIdentifier.dom_id(note)
        )
      end
    end
  end

  private

  # The set of highlights the group bible shows for a given verse: any
  # highlight anchored to a note shared with the group.
  def visible_highlights_for(verse, group)
    Highlight
      .joins(highlight_notes: { note: :note_shares })
      .where(note_shares: { shareable_type: "Group", shareable_id: group.id })
      .where("osis_ref LIKE ?", "Bible.%.#{verse.chapter.book.osis_code}.#{verse.chapter.number}.%")
      .distinct
  end

  # For a note, list every (translation, book, chapter) tuple the note
  # appears on. A note attached to highlights in different chapters
  # would yield multiple tuples.
  def target_chapters_for(note)
    note.highlights.flat_map do |h|
      ref = OsisRef.parse(h.osis_ref)
      [ { translation: ref.translation_code, book: ref.start_book, chapter: ref.start_chapter } ]
    end.uniq
  end
end
