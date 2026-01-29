class Note < ApplicationRecord
  # :private and :public clash with Ruby keywords and Rails generated
  # enum methods (note.private? etc). Keeping the stored values as
  # private_note / public_note. The UI still labels them "Private" /
  # "Public".
  VISIBILITIES = {
    private_note:  0,
    shared_users:  1,
    shared_groups: 2,
    public_note:   3
  }.freeze

  enum :visibility, VISIBILITIES

  has_rich_text :body

  belongs_to :user
  has_many :highlight_notes, dependent: :destroy
  has_many :highlights, through: :highlight_notes

  validates :body, presence: true
end
