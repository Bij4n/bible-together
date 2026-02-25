class HighlightNote < ApplicationRecord
  belongs_to :highlight
  belongs_to :note

  validates :highlight_id, uniqueness: { scope: :note_id }
end
