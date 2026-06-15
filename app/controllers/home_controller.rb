class HomeController < ApplicationController
  COMMUNITY_NOTE_LIMIT = 3

  def show
    @community_entries = community_entries
  end

  def how_it_works
  end

  private

  # Returns up to COMMUNITY_NOTE_LIMIT public notes with their verse.
  def community_entries
    Note.public_visible
        .includes(:user, :highlights)
        .order(created_at: :desc)
        .limit(COMMUNITY_NOTE_LIMIT * 2)
        .filter_map do |note|
      verse = verse_for_note(note)
      verse && [ note, verse ]
    end.take(COMMUNITY_NOTE_LIMIT)
  end

  def verse_for_note(note)
    highlight = note.highlights.first
    return nil unless highlight

    parsed = OsisRef.parse(highlight.osis_ref, strict: :same_chapter)
    Verse.where(osis_ref: parsed.verse_osis_refs)
         .includes(chapter: { book: :translation })
         .first
  rescue OsisRef::ParseError
    nil
  end
end
