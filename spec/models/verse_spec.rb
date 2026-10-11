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

  describe ".red_text_for" do
    it "joins the red passages of a verse" do
      text = "She said, No man, Lord. And Jesus said unto her, Neither do I condemn thee: go, and sin no more."

      expect(Verse.red_text_for(text, [ [ 49, 96 ] ])).to eq("Neither do I condemn thee: go, and sin no more.")
      expect(Verse.red_text_for("Whose is this? They say, Caesar's. Render unto Caesar.", [ [ 0, 14 ], [ 35, 54 ] ]))
        .to eq("Whose is this? Render unto Caesar.")
    end

    it "is nil for a verse with no red text" do
      expect(Verse.red_text_for("In the beginning.", [])).to be_nil
    end
  end

  describe ".search_red_text" do
    it "matches only inside Jesus's words" do
      chapter = create(:chapter)
      narration = "And the people loved him. And Jesus said, Follow me."
      create(:verse, chapter: chapter, number: 1, body_text: narration, body_html: narration,
                     red_letter_ranges: [ [ 42, 52 ] ], red_text: "Follow me.", osis_ref: "Bible.KJV.Gen.1.901")
      spoken = "And Jesus said, Love your enemies."
      hit = create(:verse, chapter: chapter, number: 2, body_text: spoken, body_html: spoken,
                           red_letter_ranges: [ [ 16, 34 ] ], red_text: "Love your enemies.",
                           osis_ref: "Bible.KJV.Gen.1.902")

      expect(Verse.search_red_text("love")).to eq([ hit ])
    end
  end
end
