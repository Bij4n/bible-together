module LocaleBannerHelper
  # Returns the Translation we'd suggest the user switch to, or nil if
  # the banner shouldn't render. Conditions: we're on a reader page
  # (public or signed-in; groups opt out because groups are locked to
  # one translation), the UI locale differs from the current
  # translation's language, a translation matching the UI locale
  # exists, and the user hasn't dismissed the banner for this browser.
  def locale_banner_suggestion
    return nil if cookies.signed[:locale_banner_dismissed]
    return nil unless @translation
    return nil if controller_path.start_with?("groups/")
    return nil if @translation.language == I18n.locale.to_s

    Translation.where(language: I18n.locale.to_s)
               .where.not(id: @translation.id)
               .first
  end

  # Path to the same book/chapter in the suggested translation. Public
  # reader → public path; signed-in reader → private path.
  def locale_banner_target_path(suggested)
    args = {
      translation: suggested.code.downcase,
      book: @book.osis_code.downcase,
      chapter: @chapter.number
    }
    controller_path.start_with?("public/") ? public_bible_chapter_path(args) : bible_chapter_path(args)
  end
end
