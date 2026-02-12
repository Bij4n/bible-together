require "rails_helper"

RSpec.describe Flag, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:flaggable) }
    it { is_expected.to belong_to(:resolved_by).class_name("User").optional }
  end

  describe "reason enum" do
    it "accepts each reason" do
      %w[spam inappropriate harassment misinformation other].each do |r|
        expect(build(:flag, reason: r)).to be_valid
      end
    end

    it "rejects unknown reasons" do
      expect { build(:flag, reason: "banana") }.to raise_error(ArgumentError)
    end
  end

  describe "flaggable type whitelist" do
    it "accepts Note and Comment" do
      expect(build(:flag, flaggable: create(:note))).to be_valid
      expect(build(:flag, flaggable: create(:comment))).to be_valid
    end

    it "rejects other polymorphic targets" do
      bogus = Flag.new(user: create(:user), flaggable_type: "User", flaggable_id: 1, reason: "other")
      expect(bogus).not_to be_valid
    end
  end

  describe "uniqueness per user per flaggable" do
    it "rejects a second flag from the same user on the same content" do
      first = create(:flag)
      dup = build(:flag, user: first.user, flaggable: first.flaggable, reason: "spam")
      expect(dup).not_to be_valid
    end
  end

  describe "scopes" do
    it ".unresolved returns flags without resolved_at" do
      pending = create(:flag)
      resolved = create(:flag, resolved_at: Time.current, resolved_by: create(:user))
      expect(Flag.unresolved).to include(pending)
      expect(Flag.unresolved).not_to include(resolved)
    end
  end

  describe "#resolve!" do
    it "sets resolved_at and resolved_by" do
      admin = create(:user, admin: true)
      flag = create(:flag)
      flag.resolve!(admin)
      expect(flag.resolved_at).to be_present
      expect(flag.resolved_by).to eq(admin)
    end
  end
end
