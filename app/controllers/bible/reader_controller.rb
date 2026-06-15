module Bible
  class ReaderController < ApplicationController
    include CommunityChapterLoading

    # /bible -> the user's default translation if they've set one, else
    # KJV Genesis 1. Signed-out visitors fall through to the public
    # bible at the same default.
    def entry
      code = resolved_default_translation_code
      # Same destination either way since R7 — /bible serves the
      # community layer to guests at the same URL.
      redirect_to bible_chapter_path(translation: code.downcase, book: "gen", chapter: 1)
    end

    def show
      canonical_translation = params[:translation].downcase
      canonical_book        = params[:book].downcase

      if params[:translation] != canonical_translation || params[:book] != canonical_book
        redirect_to bible_chapter_path(translation: canonical_translation, book: canonical_book,
                                       chapter: params[:chapter],
                                       layer: params[:layer].presence),
                    status: :moved_permanently
        return
      end

      @translation = Translation.where("lower(code) = ?", canonical_translation).first!
      @book        = @translation.books.where("lower(osis_code) = ?", canonical_book).first!
      @chapter     = @book.chapters.find_by!(number: params[:chapter].to_i)
      @verses      = @chapter.verses.order(:number)

      # The community layer lives at the same URL (?layer=community,
      # Sprint R7 merge of the old /public/bible surface). Anonymous
      # visitors get it without the param — it's the only lens they
      # have, and an empty personal reader would be a dead end.
      if params[:layer] == "community" || !user_signed_in?
        load_community_chapter
        render "public/bible/show"
        return
      end

      @highlights  = load_highlights_for_chapter
      @cross_translation_highlights = load_cross_translation_highlight_map
    end

    private

    # Prefix LIKE against the indexed osis_ref column. Every highlight's
    # ref starts with "Bible.<TRANS>.<Book>.<Chapter>." by the
    # same-chapter constraint, so this catches every highlight that
    # touches the current chapter in one indexed query.
    def load_highlights_for_chapter
      return [] unless user_signed_in?

      prefix = "Bible.#{@translation.code}.#{@book.osis_code}.#{@chapter.number}."
      # includes(:notes) so render_verse_with_highlights can read
      # highlight.notes.size without an N+1 — the renderer emits
      # data-note-count on the dominant highlight span (Sprint 16.5
      # PR C: drives the confirm-or-instant-remove branch on the
      # color-toggle removal pattern).
      current_user.highlights.includes(:notes).for_chapter(prefix).to_a
    end

    def resolved_default_translation_code
      user_signed_in? && current_user.default_translation&.code || "KJV"
    end

    # Returns a hash mapping verse_number => other_translation_code for
    # verses in the current chapter that the user has highlighted in a
    # different translation. Used by the verse partial to render the
    # bridge badge as a link into that other translation.
    #
    # If two different translations both touch the same verse, the first
    # one encountered wins — with KJV + RV1909 that case doesn't arise,
    # but it's safe enough for a future third translation too.
    def load_cross_translation_highlight_map
      return {} unless user_signed_in?

      cross = current_user.highlights.from_other_translations_in_chapter(
        translation_code: @translation.code,
        book:             @book.osis_code,
        chapter:          @chapter.number
      )

      cross.each_with_object({}) do |h, acc|
        code = h.translation.code
        h.parsed_ref.verse_osis_refs.each do |ref|
          n = ref.split(".").last.to_i
          acc[n] ||= code
        end
      rescue OsisRef::ParseError
        # Shouldn't happen — validators gate on parse — but a stale row
        # with a malformed ref shouldn't break the reader.
        next
      end
    end
  end
end
