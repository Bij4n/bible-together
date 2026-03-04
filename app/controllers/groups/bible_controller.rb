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

      # Own highlights in this chapter, plus every highlight anchored by
      # a note that's been shared with this group. Highlights themselves
      # carry the color; the shared note indicator is rendered separately
      # from the list of @group_notes below.
      own        = current_user.highlights.for_chapter(prefix).to_a
      group_hs   = Highlight
                   .joins(highlight_notes: { note: :note_shares })
                   .where(note_shares: { shareable_type: "Group", shareable_id: @group.id })
                   .for_chapter(prefix)
                   .distinct
                   .to_a
      @highlights = (own + group_hs).uniq { |h| h.id }

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
