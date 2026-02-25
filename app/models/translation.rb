class Translation < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :highlights, dependent: :destroy

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :language, presence: true
end
