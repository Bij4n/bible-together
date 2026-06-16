class ForumPost < ApplicationRecord
  belongs_to :forum_thread
  belongs_to :user
  belongs_to :hidden_by, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: 5000 }

  scope :visible, -> { where(hidden_at: nil) }

  after_create :mark_thread_posted

  def hidden?
    hidden_at.present?
  end

  def hide!(admin)
    update!(hidden_at: Time.current, hidden_by: admin)
  end

  def unhide!
    update!(hidden_at: nil, hidden_by: nil)
  end

  private

  def mark_thread_posted
    forum_thread.update_column(:last_posted_at, created_at)
  end
end
