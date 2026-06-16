class ForumThread < ApplicationRecord
  belongs_to :user
  belongs_to :hidden_by, class_name: "User", optional: true
  has_many :forum_posts, dependent: :destroy

  validates :title, presence: true, length: { maximum: 150 }

  scope :visible, -> { where(hidden_at: nil) }
  scope :recent,  -> { order(Arel.sql("COALESCE(last_posted_at, created_at) DESC")) }

  def hidden?
    hidden_at.present?
  end

  def hide!(admin)
    update!(hidden_at: Time.current, hidden_by: admin)
  end

  def unhide!
    update!(hidden_at: nil, hidden_by: nil)
  end
end
