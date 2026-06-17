module AuthorsHelper
  def profile_note_stats(author, viewer:)
    stats = author.note_stats
    if viewer.present? && viewer == author
      [
        [ t("authors.stats.total"), stats[:total] ],
        [ t("authors.stats.public"), stats[:public] ],
        [ t("authors.stats.private"), stats[:private] ],
        [ t("authors.stats.shared"), stats[:shared] ]
      ]
    else
      [ [ t("authors.stats.public"), stats[:public] ] ]
    end
  end
end
