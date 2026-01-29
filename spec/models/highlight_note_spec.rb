require "rails_helper"

RSpec.describe HighlightNote, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:highlight) }
    it { is_expected.to belong_to(:note) }
  end

  describe "uniqueness" do
    it "disallows the same highlight + note pair twice" do
      hn = create(:highlight_note)
      dup = build(:highlight_note, highlight: hn.highlight, note: hn.note)
      expect(dup).not_to be_valid
    end
  end
end
