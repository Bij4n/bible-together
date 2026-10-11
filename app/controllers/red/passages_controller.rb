module Red
  # The lists of curated passages in Highlighted in Red: parables,
  # encounters and sayings. Reading one is
  # Bible::ReaderController#passage, since a passage is read in the
  # same reader as a chapter.
  class PassagesController < ApplicationController
    def index
      @collection = params[:collection]
      @groups =
        if @collection == "parables"
          [ { id: "parables", heading: t("red.parables.parables_heading"), note: nil,
              passages: Bible::Passages.of_kind("parable") },
            { id: "word-pictures", heading: t("red.parables.word_pictures_heading"),
              note: t("red.parables.word_pictures_note"), passages: Bible::Passages.of_kind("word_picture") } ]
        else
          [ { id: @collection, heading: t("red.#{@collection}.title"), note: nil,
              passages: Bible::Passages.in_collection(@collection) } ]
        end
    end
  end
end
