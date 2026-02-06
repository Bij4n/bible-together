module Groups
  class BibleController < ApplicationController
    before_action :authenticate_user!
    before_action :load_group
    before_action :ensure_group_member

    def show
      canonical_translation = params[:translation].downcase
      canonical_book        = params[:book].downcase

      @translation = Translation.where("lower(code) = ?", canonical_translation).first!
      @book        = @translation.books.where("lower(osis_code) = ?", canonical_book).first!
      @chapter     = @book.chapters.find_by!(number: params[:chapter].to_i)
      @verses      = @chapter.verses.order(:number)

      prefix = "Bible.#{@translation.code}.#{@book.osis_code}.#{@chapter.number}."

      # Sprint 5: the group bible shows only highlights anchored to a
      # note shared with this group. Each viewer's private highlights
      # stay on /bible/... — keeping group-view content identical
      # across members means a single broadcast can replace a verse for
      # everyone. A future sprint can layer per-user highlights as a
      # client-side overlay without re-rendering the server HTML.
      @highlights = Highlight
                    .joins(highlight_notes: { note: :note_shares })
                    .where(note_shares: { shareable_type: "Group", shareable_id: @group.id })
                    .for_chapter(prefix)
                    .distinct
                    .to_a

      @group_notes = Note
                     .shared_with_group(@group)
                     .joins(:highlights)
                     .where(highlights: { osis_ref: @highlights.map(&:osis_ref) })
                     .includes(:user, :highlights)
                     .distinct
    end

    private

    def load_group
      @group = Group.find(params[:group_id])
    end

    def ensure_group_member
      head :not_found unless @group.member?(current_user)
    end
  end
end
