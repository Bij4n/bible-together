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
      { contact_form: { name: "Ruth", email: "ruth@example.com", message: "A question about a verse." } }
    end

    it "enqueues the contact email and redirects back to the contact page" do
      expect {
        post "/contact", params: valid_params
      }.to have_enqueued_mail(ContactMailer, :contact_message)

      expect(response).to redirect_to(contact_path)
    end

    it "re-renders with an error and sends nothing when email and message are blank" do
      expect {
        post "/contact", params: { contact_form: { name: "Ruth", email: "", message: "" } }
      }.not_to have_enqueued_mail(ContactMailer, :contact_message)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
