# The global public-notes feed (Sprint R7): every public note, newest
# first (or by popularity with ?sort=top), optionally filtered to one
# book, paginated with a load-more link. Fully public — the per-chapter
# community reading layer stays in the bible reader; this is the
# browse-everything surface.
class CommunityController < ApplicationController
  PER_PAGE = 25

  def index
    @sort = params[:sort] == "top" ? "top" : "recent"
    @book = params[:book].presence
    @page = [ params[:page].to_i, 1 ].max

    scope = Note.public_visible.includes(:user, :comments, :highlights)
    if @book
      # EXISTS instead of a join: no row duplication for multi-highlight
      # notes, so no DISTINCT — which sorted_for_public's select-alias
      # ordering can't survive.
      scope = scope.where(<<~SQL.squish, pattern: "Bible.%.#{Note.sanitize_sql_like(@book)}.%")
        EXISTS (
          SELECT 1 FROM highlight_notes hn
          INNER JOIN highlights h ON h.id = hn.highlight_id
          WHERE hn.note_id = notes.id AND h.osis_ref LIKE :pattern
        )
      SQL
    end

    scope = @sort == "top" ? scope.sorted_for_public : scope.order(created_at: :desc)

    # Fetch one extra row to know whether a next page exists without a
    # second COUNT over the DISTINCT join.
    notes = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @has_more = notes.size > PER_PAGE
    @notes = notes.first(PER_PAGE)

    # Book filter options: the 66 canonical books from the first
    # installed translation (osis codes are translation-neutral).
    @books = Book.where(translation: Translation.order(:id).first).order(:position)
  end
end
