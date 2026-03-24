class Flag < ApplicationRecord
  REASONS = %w[spam inappropriate harassment misinformation other].freeze
  FLAGGABLE_TYPES = %w[Note Comment].freeze

  enum :reason, REASONS.index_with(&:itself)

  belongs_to :user
  belongs_to :flaggable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :flaggable_type, inclusion: { in: FLAGGABLE_TYPES }
  validates :details, length: { maximum: 1_000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: [ :flaggable_type, :flaggable_id ] }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved,   -> { where.not(resolved_at: nil) }

  def resolve!(admin)
    update!(resolved_at: Time.current, resolved_by: admin)
  end
end
