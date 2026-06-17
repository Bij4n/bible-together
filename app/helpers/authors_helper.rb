module AuthorsHelper
  def profile_note_stats(author, viewer:)
    stats = author.note_stats
    if viewer.present? && viewer == author
      [
        [ t("authors.stats.private"), stats[:private] ],
        [ t("authors.stats.public"), stats[:public] ]
      ]
    else
      [ [ t("authors.stats.public"), stats[:public] ] ]
    end
  end
end
