# Loads the community layer's data for a chapter: public notes anchored
# to it (admins also see hidden ones for in-place moderation) and the
# highlights those notes ride on. Shared by the bible reader's
# ?layer=community branch; extracted from the pre-R7 standalone
# Public::BibleController.
module CommunityChapterLoading
  extend ActiveSupport::Concern

  private

  def load_community_chapter
    prefix = "Bible.#{@translation.code}.#{@book.osis_code}.#{@chapter.number}."
    @public_notes = community_notes_for(prefix)
    @highlights   = community_highlights_for(@public_notes)
  end

  def community_notes_for(prefix)
    scope = Note.public_visible
    scope = scope.or(Note.where(visibility: Note.visibilities[:public_note])) if current_user&.admin?
    scope
      .joins(:highlights)
      .where(highlights: { osis_ref: community_osis_refs_for(prefix) })
      .includes(:user, :highlights)
      .sorted_for_public
      .distinct
  end

  def community_highlights_for(notes)
    ids = notes.flat_map(&:highlights).map(&:id).uniq
    # includes(:notes) — render_verse_with_highlights reads
    # highlight.notes.size to emit data-note-count; same eager-load
    # guard as the personal reader so the renderer's contract is
    # uniform.
    Highlight.where(id: ids).includes(:notes).to_a
  end

  def community_osis_refs_for(prefix)
    Verse
      .joins(chapter: :book)
      .where(books: { translation_id: @translation.id, osis_code: @book.osis_code },
             chapters: { number: @chapter.number })
      .pluck(:osis_ref)
  end
end
