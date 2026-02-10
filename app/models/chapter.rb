class Chapter < ApplicationRecord
  belongs_to :book
  has_many :verses, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :book_id }
end
