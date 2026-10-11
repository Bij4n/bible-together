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

      # A study of Highlighted in Red reads under the red lens and
      # steps only through chapters that have his words. The lens is a
      # class on the page, so the shared verse broadcasts are the same
      # for every member whatever they have toggled.
      if @group.focus_red?
        @lens = :red
        @red_index = Bible::RedLetterIndex.for(@translation)
      end

      load_shared_layer
    end

    # /studies/:id/passages/:slug -> one passage from the study's list,
    # in the study's reader. Every telling sits inside one chapter, so
    # the page subscribes to that chapter's stream like any other and
    # live updates work unchanged.
    def passage
      @passage = @group.passages.detect { |candidate| candidate.slug == params[:slug] }
      return head(:not_found) unless @passage

      @lens        = :red
      @translation = passage_translation
      @appearances = appearances_available_in(@translation, @passage)
      @appearance  = chosen_appearance
      return head(:not_found) unless @appearance

      @book    = @translation.books.find_by!(osis_code: @appearance.book)
      @chapter = @book.chapters.find_by!(number: @appearance.chapter)
      @verses  = @chapter.verses.where(number: @appearance.verses).order(:number)

      load_shared_layer
      keep_notes_on_passage
      render :show
    end

    private

    # Highlights anchored to a note shared with this study, and those
    # notes, for the chapter on screen.
    #
    # Sprint 5: the group bible shows only highlights anchored to a
    # note shared with this group. Each viewer's private highlights
    # stay on /bible/... — keeping group-view content identical
    # across members means a single broadcast can replace a verse for
    # everyone. A future sprint can layer per-user highlights as a
    # client-side overlay without re-rendering the server HTML.
    def load_shared_layer
      prefix = "Bible.#{@translation.code}.#{@book.osis_code}.#{@chapter.number}."

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

    # ?translation= wins, then the reader's own default, then Spanish
    # scripture for a Spanish-language reader, then the KJV.
    def passage_translation
      code = params[:translation].presence&.upcase
      return Translation.find_by!(code: code) if code

      current_user.default_translation ||
        (Translation.find_by(code: "RV1909") if I18n.locale == :es) ||
        Translation.find_by!(code: "KJV")
    end

    # The tellings whose verses this translation actually has.
    def appearances_available_in(translation, passage)
      first_refs = passage.appearances.to_h { |a| [ a.osis_refs(translation.code).first, a ] }
      found = Verse.where(osis_ref: first_refs.keys).pluck(:osis_ref)
      first_refs.select { |ref, _| found.include?(ref) }.values
    end

    def chosen_appearance
      return @appearances.first if params[:in].blank?

      @appearances.detect { |a| a.book.casecmp?(params[:in]) }
    end

    # The shared layer loads a chapter at a time. On a passage page,
    # drop the notes anchored elsewhere in the chapter.
    def keep_notes_on_passage
      @group_notes = @group_notes.select do |note|
        note.highlights.any? do |highlight|
          ref = highlight.parsed_ref
          ref.start_verse <= @appearance.verses.last && ref.end_verse >= @appearance.verses.first
        end
      end
    end

    def load_group
      @group = Group.find(params[:group_id])
    end

    def ensure_group_member
      head :not_found unless @group.member?(current_user)
    end
  end
end
