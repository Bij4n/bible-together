module NavigationHelper
  def read_nav_path
    if user_signed_in?
      continue_reading_path(current_user)
    else
      bible_entry_path
    end
  end

  def community_bible_path
    bible_chapter_path(translation: "kjv", book: "gen", chapter: 1, layer: "community")
  end

  def read_nav_active?
    request.path.start_with?("/bible") && params[:layer] != "community"
  end

  # Highlighted in Red is its own destination: the front page, the red
  # reader and the lists all sit under /red.
  def red_nav_active?
    request.path == "/red" || request.path.start_with?("/red/")
  end

  def study_nav_active?
    request.path.start_with?("/studies", "/notes") ||
      (controller_name == "home" && action_name == "how_it_works")
  end

  def explore_nav_active?
    request.path.start_with?("/community", "/search") ||
      nav_active?(discover_groups_path) ||
      (request.path.start_with?("/bible") && params[:layer] == "community")
  end

  def you_nav_active?
    request.path.start_with?("/settings") ||
      (controller_name == "authors" && action_name == "show" && params[:id].to_s == current_user&.id.to_s)
  end

  def user_initials(user)
    if user.display_name.present?
      parts = user.display_name.split(/\s+/)
      if parts.size >= 2
        "#{parts.first[0]}#{parts.last[0]}"
      else
        parts.first[0, 2]
      end
    else
      user.email.to_s.split("@").first.to_s[0, 2]
    end.upcase
  end

  def continue_reading_location(user)
    highlight = user.highlights.order(updated_at: :desc).first
    if highlight
      parts = highlight.osis_ref.to_s.split(".")
      if parts.size >= 4
        translation = parts[1].downcase
        book = parts[2].downcase
        chapter = parts[3].to_i
        book_record = Book.joins(:translation)
                          .where(translations: { code: parts[1] })
                          .find_by(osis_code: parts[2])
        name = book_record ? (I18n.locale == :es ? book_record.name_es : book_record.name_en) : parts[2]
        return {
          label: "#{name} #{chapter}",
          path: focused_chapter_path(user, book_record&.translation, parts[2], chapter) ||
                bible_chapter_path(translation: translation, book: book, chapter: chapter)
        }
      end
    end

    code = user.default_translation&.code&.downcase || "kjv"
    if user.focus_red? && (start = red_starting_location(code))
      return start
    end

    book_record = Book.joins(:translation)
                      .where(translations: { code: code.upcase })
                      .find_by(osis_code: "Gen")
    name = book_record ? (I18n.locale == :es ? book_record.name_es : book_record.name_en) : "Genesis"
    {
      label: "#{name} 1",
      path: bible_chapter_path(translation: code, book: "gen", chapter: 1)
    }
  end

  # For a reader studying Highlighted in Red: the chapter under the red
  # lens, when it has any red text. nil otherwise, and the ordinary
  # reader is used.
  def focused_chapter_path(user, translation, book_code, chapter)
    return unless user.focus_red? && translation
    return unless Bible::RedLetterIndex.for(translation).include?(book_code, chapter)

    red_chapter_path(translation: translation.code.downcase, book: book_code.downcase, chapter: chapter)
  end

  # Where a reader studying Highlighted in Red starts: the first
  # chapter with red text in their translation.
  def red_starting_location(code)
    translation = Translation.find_by(code: code.upcase) or return
    first = Bible::RedLetterIndex.for(translation).first or return
    book = translation.books.find_by(osis_code: first.book)
    name = book ? (I18n.locale == :es ? book.name_es : book.name_en) : first.book

    { label: "#{name} #{first.number}",
      path: red_chapter_path(translation: code, book: first.book.downcase, chapter: first.number) }
  end

  def continue_reading_path(user)
    continue_reading_location(user)[:path]
  end
end
