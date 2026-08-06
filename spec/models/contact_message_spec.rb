require "rails_helper"

RSpec.describe ContactMessage, type: :model do
  it "is valid with name, email, and message" do
    message = described_class.new(
      name: "Ruth",
      email: "ruth@example.com",
      message: "A question about a verse."
    )

    expect(message).to be_valid
  end

  it "is valid without a name" do
    expect(described_class.new(email: "ruth@example.com", message: "A question.")).to be_valid
  end

  it "requires an email" do
    expect(described_class.new(email: "", message: "A question.")).not_to be_valid
  end

  it "rejects a malformed email" do
    expect(described_class.new(email: "not-an-email", message: "A question.")).not_to be_valid
  end

  it "requires a message" do
    expect(described_class.new(email: "ruth@example.com", message: "")).not_to be_valid
  end

  it "rejects a message longer than 5000 chars" do
    expect(described_class.new(email: "ruth@example.com", message: "x" * 5001)).not_to be_valid
  end

  it "rejects a name longer than 120 chars" do
    message = described_class.new(name: "x" * 121, email: "ruth@example.com", message: "A question.")

    expect(message).not_to be_valid
  end
end
