class Verse < ApplicationRecord
  include PgSearch::Model

  belongs_to :chapter
  has_one :verse_embedding, dependent: :destroy

  scope :with_embeddings, -> { joins(:verse_embedding) }

  validates :number, presence: true, uniqueness: { scope: :chapter_id }
  validates :body_text, presence: true
  validates :osis_ref, presence: true, uniqueness: true

  # Keyword search over verse text. Prefix matches so "lov" hits "loved";
  # ts_headline wraps matched terms in <mark> so the view can render the
  # highlighted fragment directly. body_text is plain text, so the
  # highlighted output is safe to html_safe.
  pg_search_scope :search_text,
                  against: :body_text,
                  using: {
                    tsearch: {
                      prefix: true,
                      highlight: {
                        StartSel: "<mark>",
                        StopSel:  "</mark>"
                      }
                    }
                  }

  # The same search, but only inside Jesus's words. red_text holds a
  # verse's red passages on their own, so a match in the narration
  # around them doesn't count and the highlighted snippet is his words.
  pg_search_scope :search_red_text,
                  against: :red_text,
                  using: {
                    tsearch: {
                      prefix: true,
                      highlight: {
                        StartSel: "<mark>",
                        StopSel:  "</mark>"
                      }
                    }
                  }

  # What red_text should hold for a verse: its red passages joined by a
  # space, or nil when it has none. Everything that writes
  # red_letter_ranges writes this beside it.
  def self.red_text_for(body_text, ranges)
    Array(ranges).map { |from, to| body_text[from...to] }.join(" ").presence
  end
end
