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

  describe "#previous / #next" do
    let(:translation) { create(:translation) }
    let(:gen)  { create(:book, translation: translation, osis_code: "Gen",  position: 1, testament: :old) }
    let(:exod) { create(:book, translation: translation, osis_code: "Exod", position: 2, testament: :old) }

    let!(:gen1)  { create(:chapter, book: gen, number: 1) }
    let!(:gen2)  { create(:chapter, book: gen, number: 2) }
    let!(:gen50) { create(:chapter, book: gen, number: 50) }
    let!(:exod1) { create(:chapter, book: exod, number: 1) }

    it "walks within a book" do
      expect(gen1.next).to eq(gen2)
      expect(gen2.previous).to eq(gen1)
    end

    it "crosses book boundaries forward" do
      expect(gen50.next).to eq(exod1)
    end

    it "crosses book boundaries backward" do
      expect(exod1.previous).to eq(gen50)
    end

    it "returns nil at the canon edges" do
      expect(gen1.previous).to be_nil
    end
  end
end
