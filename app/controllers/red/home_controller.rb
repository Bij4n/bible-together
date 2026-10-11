module Red
  # The front page of Highlighted in Red: three ways in (his words, his
  # parables, his encounters) and the themes that cut across them.
  class HomeController < ApplicationController
    def show
      @themes = Bible::Themes.all
    end
  end
end
