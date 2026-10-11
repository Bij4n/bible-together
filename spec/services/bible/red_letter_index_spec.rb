require "rails_helper"

RSpec.describe Bible::RedLetterIndex do
  let!(:kjv) { create(:translation, :kjv) }

  def chapter_with(book, number, red:)
    chapter = create(:chapter, book: book, number: number)
    create(:verse, chapter: chapter, number: 1, body_text: "Follow me.", body_html: "Follow me.",
                   red_letter_ranges: red ? [ [ 0, 10 ] ] : [],
                   osis_ref: "Bible.#{book.translation.code}.#{book.osis_code}.#{number}.1")
    chapter
  end

  let(:genesis) { create(:book, translation: kjv, osis_code: "Gen", name_en: "Genesis", name_es: "Génesis", position: 1, testament: :old) }
  let(:matthew) { create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo", position: 40, testament: :new) }
  let(:john)    { create(:book, translation: kjv, osis_code: "John", name_en: "John", name_es: "Juan", position: 43, testament: :new) }

  before do
    chapter_with(genesis, 1, red: false)
    chapter_with(john, 3, red: true)
    chapter_with(matthew, 4, red: true)
    chapter_with(matthew, 3, red: true)
    chapter_with(matthew, 2, red: false)
  end

  subject(:index) { described_class.for(kjv) }

  it "lists only chapters with red text, in canon order" do
    expect(index.chapters.map { |c| [ c.book, c.number ] })
      .to eq([ [ "Matt", 3 ], [ "Matt", 4 ], [ "John", 3 ] ])
  end

  it "knows whether a chapter has red text" do
    expect(index.include?("Matt", 3)).to be true
    expect(index.include?("Matt", 2)).to be false
    expect(index.include?("Gen", 1)).to be false
  end

  it "steps to the neighbouring red chapters, across books" do
    expect(index.before("John", 3).to_a).to eq([ "Matt", 4 ])
    expect(index.after("Matt", 4).to_a).to eq([ "John", 3 ])
    expect(index.before("Matt", 3)).to be_nil
    expect(index.after("John", 3)).to be_nil
  end

  it "lists the books and each book's red chapters" do
    expect(index.books).to eq(%w[Matt John])
    expect(index.chapters_in("Matt")).to eq([ 3, 4 ])
    expect(index.first.to_a).to eq([ "Matt", 3 ])
  end

  it "is scoped to the translation" do
    other = create(:translation, code: "RV1909", name: "Reina-Valera 1909", language: "es")

    expect(described_class.for(other).chapters).to be_empty
  end
end
