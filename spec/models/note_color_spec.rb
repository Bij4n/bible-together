require "rails_helper"

RSpec.describe Note, type: :model do
  describe "color" do
    it "accepts note marker colors" do
      note = build(:note, color: "violet")
      expect(note).to be_valid
    end

    it "rejects highlight colors" do
      note = build(:note, color: "yellow")
      expect(note).not_to be_valid
    end
  end
end
