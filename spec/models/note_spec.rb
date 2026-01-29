require "rails_helper"

RSpec.describe Note, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:highlight_notes).dependent(:destroy) }
    it { is_expected.to have_many(:highlights).through(:highlight_notes) }
    it { is_expected.to have_rich_text(:body) }
  end

  describe "visibility enum" do
    it "defaults to private_note" do
      expect(Note.new.visibility).to eq("private_note")
    end

    it "accepts each visibility" do
      %w[private_note shared_users shared_groups public_note].each do |v|
        expect(build(:note, visibility: v)).to be_valid
      end
    end

    it "rejects unknown visibilities" do
      expect { build(:note, visibility: "top-secret") }.to raise_error(ArgumentError)
    end
  end

  describe "body" do
    it "requires a body" do
      note = build(:note, body: nil)
      expect(note).not_to be_valid
      expect(note.errors[:body]).to be_present
    end

    it "stores Action Text rich content" do
      note = create(:note, body: "<p>A <strong>marvelous</strong> light.</p>")
      expect(note.reload.body.to_s).to include("<strong>marvelous</strong>")
    end
  end
end
