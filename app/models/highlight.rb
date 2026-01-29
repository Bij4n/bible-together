class Highlight < ApplicationRecord
  # Muted manuscript-appropriate tones. Specific hex values live in the
  # CSS (app/assets/tailwind/application.css) so light and dark mode
  # overlays can be tuned independently.
  COLORS = %w[gold rose sage lavender sky].freeze

  enum :color, COLORS.each_with_index.to_h

  belongs_to :user
  belongs_to :translation

  has_many :highlight_notes, dependent: :destroy
  has_many :notes, through: :highlight_notes

  validates :osis_ref, presence: true
  validates :user_id, uniqueness: { scope: [ :osis_ref, :color ] }
  validate  :osis_ref_is_parseable

  scope :for_chapter, ->(prefix) { where("osis_ref LIKE ?", "#{sanitize_sql_like(prefix)}%") }

  def parsed_ref
    @parsed_ref ||= OsisRef.parse(osis_ref, strict: :same_chapter)
  end

  private

  def osis_ref_is_parseable
    return if osis_ref.blank?

    OsisRef.parse(osis_ref, strict: :same_chapter)
  rescue OsisRef::ParseError => e
    errors.add(:osis_ref, e.message)
  end
end
