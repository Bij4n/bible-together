class Verse < ApplicationRecord
  belongs_to :chapter

  validates :number, presence: true, uniqueness: { scope: :chapter_id }
  validates :body_text, presence: true
  validates :osis_ref, presence: true, uniqueness: true
end
