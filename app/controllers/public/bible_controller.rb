module Public
  # Legacy URL shim (Sprint R7): the community reader merged into
  # Bible::ReaderController as ?layer=community. These 301s keep old
  # bookmarks, backlinks, and search-engine entries working.
  class BibleController < ApplicationController
    def show
      redirect_to bible_chapter_path(translation: params[:translation].downcase,
                                     book: params[:book].downcase,
                                     chapter: params[:chapter],
                                     layer: "community"),
                  status: :moved_permanently
    end
  end
end
