module Red
  # The lists of curated passages in Highlighted in Red. Reading one is
  # Bible::ReaderController#passage, since a passage is read in the
  # same reader as a chapter.
  class PassagesController < ApplicationController
    def index
      @parables      = Bible::Passages.of_kind("parable")
      @word_pictures = Bible::Passages.of_kind("word_picture")
    end
  end
end
