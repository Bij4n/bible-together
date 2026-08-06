require "rails_helper"

RSpec.describe MailEvent, type: :model do
  it "is valid with an event type and svix id" do
    expect(build(:mail_event)).to be_valid
  end

  it "requires an event type" do
    expect(build(:mail_event, event_type: nil)).not_to be_valid
  end

  it "requires an svix id" do
    expect(build(:mail_event, svix_id: nil)).not_to be_valid
  end

  # Svix retries any non-2xx response, so the same event can arrive more
  # than once. The svix id is the idempotency key.
  it "rejects a duplicate svix id" do
    create(:mail_event, svix_id: "msg_dupe")

    expect(build(:mail_event, svix_id: "msg_dupe")).not_to be_valid
  end

  it "enforces svix id uniqueness in the database, not just the model" do
    create(:mail_event, svix_id: "msg_race")

    expect {
      described_class.new(event_type: "email.bounced", svix_id: "msg_race").save!(validate: false)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".records?" do
    it "records the failure and suppression events" do
      %w[
        email.bounced email.complained email.delivery_delayed
        email.failed email.suppressed suppression.added suppression.removed
      ].each do |type|
        expect(described_class.records?(type)).to be(true), "expected #{type} to be recorded"
      end
    end

    # The point of this table is making failures visible, not mirroring
    # Resend's whole event stream.
    it "ignores routine delivery events" do
      %w[email.sent email.delivered email.opened email.clicked email.scheduled].each do |type|
        expect(described_class.records?(type)).to be(false), "expected #{type} to be ignored"
      end
    end

    it "ignores an unknown event type" do
      expect(described_class.records?("email.something_new")).to be(false)
      expect(described_class.records?(nil)).to be(false)
    end
  end

  describe ".recent_first" do
    it "orders by when the event occurred, newest first" do
      older = create(:mail_event, svix_id: "msg_old", occurred_at: 2.days.ago)
      newer = create(:mail_event, svix_id: "msg_new", occurred_at: 1.hour.ago)

      expect(described_class.recent_first.to_a).to eq([ newer, older ])
    end
  end
end
