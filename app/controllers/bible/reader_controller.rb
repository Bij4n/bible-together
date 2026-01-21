module Bible
  class ReaderController < ApplicationController
    def show
      canonical_translation = params[:translation].downcase
      canonical_book        = params[:book].downcase
      if params[:translation] != canonical_translation || params[:book] != canonical_book
        redirect_to bible_chapter_path(translation: canonical_translation, book: canonical_book, chapter: params[:chapter]),
                    status: :moved_permanently
        return
      end

      @translation = Translation.where("lower(code) = ?", canonical_translation).first!
      @book        = @translation.books.where("lower(osis_code) = ?", canonical_book).first!
      @chapter     = @book.chapters.find_by!(number: params[:chapter].to_i)
      @verses      = @chapter.verses.order(:number)
    end
  end
end
