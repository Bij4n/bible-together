require "rails_helper"

RSpec.describe Verse, type: :model do
  describe "validations" do
    subject { build(:verse) }

    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_presence_of(:body_text) }
    it { is_expected.to validate_presence_of(:osis_ref) }

    it "requires number uniqueness scoped to chapter" do
      verse = create(:verse, number: 16)
      dup = build(:verse, chapter: verse.chapter, number: 16, osis_ref: "#{verse.osis_ref}x")
      expect(dup).not_to be_valid
      expect(dup.errors[:number]).to be_present
    end

    it "requires osis_ref uniqueness" do
      verse = create(:verse)
      dup = build(:verse, osis_ref: verse.osis_ref)
      expect(dup).not_to be_valid
      expect(dup.errors[:osis_ref]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:chapter) }
  end

  describe "#red_letter_ranges" do
    it "defaults to an empty array" do
      verse = Verse.new
      expect(verse.red_letter_ranges).to eq([])
    end

    it "round-trips nested integer pairs through jsonb" do
      chapter = create(:chapter)
      verse = create(:verse,
                     chapter: chapter,
                     red_letter_ranges: [ [ 0, 10 ], [ 42, 57 ] ],
                     osis_ref: "Bible.KJV.John.3.16.roundtrip")
      expect(verse.reload.red_letter_ranges).to eq([ [ 0, 10 ], [ 42, 57 ] ])
    end
  end
end
