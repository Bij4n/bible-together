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

  # Matches on the chapter prefix rather than exact verse refs: a
  # highlight on part of a verse carries character offsets
  # ("...John.3.16!4-...John.3.16!19"), which an exact match on the
  # verse's own ref never finds.
  def community_notes_for(prefix)
    scope = Note.public_visible
    scope = scope.or(Note.where(visibility: Note.visibilities[:public_note])) if current_user&.admin?
    scope
      .joins(:highlights)
      .merge(Highlight.for_chapter(prefix))
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
end
