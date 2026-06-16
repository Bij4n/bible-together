class HomeController < ApplicationController
  include NavigationHelper

  COMMUNITY_NOTE_LIMIT = 3
  RECENT_NOTES_LIMIT = 5
  ACTIVE_STUDIES_LIMIT = 5

  def show
    if user_signed_in?
      @continue_reading = continue_reading_location(current_user)
      @recent_notes = current_user.notes.order(updated_at: :desc).limit(RECENT_NOTES_LIMIT)
      @active_studies = current_user.groups.distinct.order(updated_at: :desc).limit(ACTIVE_STUDIES_LIMIT)
    else
      @community_entries = community_entries
    end
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
