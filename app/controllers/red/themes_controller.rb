module Red
  # Themes in Highlighted in Red. A theme's page sets what Jesus did
  # beside what he said and the stories he told.
  class ThemesController < ApplicationController
    def index
      @themes = Bible::Themes.all
    end

    def show
      @theme = Bible::Themes.find(params[:slug]) or raise ActiveRecord::RecordNotFound
      by_kind = @theme.passages.group_by(&:kind)
      @groups = [
        { id: "did",  heading: t("red.themes.did"),  passages: by_kind.fetch("encounter", []) },
        { id: "said", heading: t("red.themes.said"), passages: by_kind.fetch("saying", []) },
        { id: "told", heading: t("red.themes.told"),
          passages: by_kind.fetch("parable", []) + by_kind.fetch("word_picture", []) }
      ].reject { |group| group[:passages].empty? }
    end
  end
end
