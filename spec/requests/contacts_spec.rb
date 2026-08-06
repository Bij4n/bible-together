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

    # A bot submission is what hard-bounced the notification address and
    # put it on Resend's suppression list, so the form gets the same
    # honeypot the donate form has.
    describe "honeypot" do
      it "drops the submission without persisting when the honeypot is filled" do
        expect {
          post "/contact", params: valid_params.merge(website: "http://spam.example")
        }.not_to change(ContactMessage, :count)
      end

      it "sends nothing when the honeypot is filled" do
        expect {
          post "/contact", params: valid_params.merge(website: "http://spam.example")
        }.not_to have_enqueued_mail(ContactMailer, :contact_message)
      end

      # Bots get an indistinguishable success so they don't learn to
      # retry with the field cleared.
      it "shows a bot the same success response a human gets" do
        post "/contact", params: valid_params.merge(website: "http://spam.example")

        expect(response).to redirect_to(contact_path)
        expect(flash[:notice]).to eq(I18n.t("contact.success"))
      end
    end

    describe "rate limiting" do
      it "refuses the submission once the per-IP hourly cap is reached" do
        5.times do |i|
          post "/contact", params: { contact_message: { name: "Ruth", email: "ruth@example.com", message: "Message #{i}." } }
        end

        expect {
          post "/contact", params: valid_params
        }.not_to change(ContactMessage, :count)

        expect(response).to have_http_status(:too_many_requests)
      end

      it "lets submissions through below the cap" do
        expect {
          3.times do |i|
            post "/contact", params: { contact_message: { name: "Ruth", email: "ruth@example.com", message: "Message #{i}." } }
          end
        }.to change(ContactMessage, :count).by(3)
      end
    end
  end
end
