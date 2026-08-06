require "rails_helper"

RSpec.describe "Contacts", type: :request do
  describe "GET /contact" do
    it "renders the contact form with the direct email address" do
      get "/contact"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("hello@bible-together.org")
      expect(response.body).to include(I18n.t("contact.submit"))
    end
  end

  describe "POST /contact" do
    let(:valid_params) do
      { contact_message: { name: "Ruth", email: "ruth@example.com", message: "A question about a verse." } }
    end

    it "persists the submission and redirects back to the contact page" do
      expect {
        post "/contact", params: valid_params
      }.to change(ContactMessage, :count).by(1)

      record = ContactMessage.last
      expect(record.name).to eq("Ruth")
      expect(record.email).to eq("ruth@example.com")
      expect(record.message).to eq("A question about a verse.")

      expect(response).to redirect_to(contact_path)
    end

    it "enqueues the notification email" do
      expect {
        post "/contact", params: valid_params
      }.to have_enqueued_mail(ContactMailer, :contact_message)
    end

    # The row is the record of truth; the email is only a notification.
    # A notification failure must not lose the submission, so delivery is
    # enqueued after the write and a raise on the way out is swallowed.
    it "still persists the submission when enqueuing the notification fails" do
      allow(ContactMailer).to receive(:contact_message).and_raise(StandardError, "resend down")

      expect {
        post "/contact", params: valid_params
      }.to change(ContactMessage, :count).by(1)

      expect(response).to redirect_to(contact_path)
    end

    it "re-renders with an error and writes nothing when email and message are blank" do
      expect {
        post "/contact", params: { contact_message: { name: "Ruth", email: "", message: "" } }
      }.not_to change(ContactMessage, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "sends nothing when the submission is invalid" do
      expect {
        post "/contact", params: { contact_message: { name: "Ruth", email: "", message: "" } }
      }.not_to have_enqueued_mail(ContactMailer, :contact_message)
    end
  end
end
