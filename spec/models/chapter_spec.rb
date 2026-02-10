require "rails_helper"

RSpec.describe Chapter, type: :model do
  describe "validations" do
    subject { build(:chapter) }

    it { is_expected.to validate_presence_of(:number) }

    it "requires number uniqueness scoped to book" do
      chapter = create(:chapter, number: 1)
      dup = build(:chapter, book: chapter.book, number: 1)
      expect(dup).not_to be_valid
      expect(dup.errors[:number]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:book) }
    it { is_expected.to have_many(:verses).dependent(:destroy) }
  end

  describe "defaults" do
    it "defaults verse_count to 0" do
      expect(Chapter.new.verse_count).to eq(0)
    end
  end
end
