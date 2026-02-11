class Chapter < ApplicationRecord
  belongs_to :book
  has_many :verses, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :book_id }

  # Previous chapter in the same book, or the last chapter of the previous
  # book in canon order. Returns nil at Genesis 1.
  def previous
    same_book = book.chapters.where("number < ?", number).order(number: :desc).first
    return same_book if same_book

    prev_book = book.translation.books.where("position < ?", book.position).ordered.last
    prev_book&.chapters&.order(number: :desc)&.first
  end

  # Next chapter in the same book, or chapter 1 of the next book. Returns
  # nil at Revelation 22.
  def next
    same_book = book.chapters.where("number > ?", number).order(:number).first
    return same_book if same_book

    next_book = book.translation.books.where("position > ?", book.position).ordered.first
    next_book&.chapters&.order(:number)&.first
  end
end
