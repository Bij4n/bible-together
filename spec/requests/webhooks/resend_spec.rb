require "rails_helper"

RSpec.describe "Resend webhooks", type: :request do
  let(:secret) { "whsec_#{Base64.strict_encode64('bible-together-webhook-test-key!')}" }

  # Bounce payload shape taken from Resend's webhook documentation. The
  # subType is literally "Suppressed" — this is the exact event that would
  # have caught the Aug 2026 contact-form outage on the first message
  # instead of the third day.
  let(:bounce_payload) do
    {
      type: "email.bounced",
      created_at: "2026-08-06T09:41:12.126Z",
      data: {
        email_id: "56761188-7520-42d8-8898-ff6fc54ce618",
        to: [ "hello@bible-together.org" ],
        from: "noreply@send.bible-together.org",
        subject: "Contact form — Ruth",
        bounce: {
          type: "Permanent",
          subType: "Suppressed",
          message: "Recipient's email on suppression list"
        }
      }
    }.to_json
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials)
      .to receive(:dig).with(:resend, :webhook_secret).and_return(secret)
  end

  def signed_headers(body, svix_id: "msg_test", timestamp: Time.current.to_i, secret_override: nil)
    key = Base64.decode64((secret_override || secret).delete_prefix("whsec_"))
    digest = Base64.strict_encode64(
      OpenSSL::HMAC.digest("SHA256", key, "#{svix_id}.#{timestamp}.#{body}")
    )

    {
      "svix-id" => svix_id,
      "svix-timestamp" => timestamp.to_s,
      "svix-signature" => "v1,#{digest}",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "a correctly signed failure event" do
    it "returns 200 and records the event" do
      expect {
        post "/webhooks/resend", params: bounce_payload, headers: signed_headers(bounce_payload)
      }.to change(MailEvent, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "extracts the fields worth querying later" do
      post "/webhooks/resend", params: bounce_payload, headers: signed_headers(bounce_payload)

      event = MailEvent.last
      expect(event.event_type).to eq("email.bounced")
      expect(event.svix_id).to eq("msg_test")
      expect(event.email_id).to eq("56761188-7520-42d8-8898-ff6fc54ce618")
      expect(event.recipient).to eq("hello@bible-together.org")
      expect(event.subject).to eq("Contact form — Ruth")
      expect(event.reason).to include("Permanent", "Suppressed", "suppression list")
      expect(event.occurred_at).to eq(Time.zone.parse("2026-08-06T09:41:12.126Z"))
    end

    # The payload shape for suppression.* events isn't documented, so the
    # raw body is kept whole rather than trusting our field mapping.
    it "keeps the full payload for forensics" do
      post "/webhooks/resend", params: bounce_payload, headers: signed_headers(bounce_payload)

      expect(MailEvent.last.payload.dig("data", "bounce", "subType")).to eq("Suppressed")
    end
  end

  describe "suppression list changes" do
    let(:payload) do
      { type: "suppression.added", created_at: "2026-08-06T09:41:12.126Z",
        data: { email: "hello@bible-together.org" } }.to_json
    end

    # Clearing this list by hand was the manual fix in Aug 2026; recording
    # the change gives that an audit trail.
    it "records them, reading the address from the suppression payload shape" do
      expect {
        post "/webhooks/resend", params: payload, headers: signed_headers(payload)
      }.to change(MailEvent, :count).by(1)

      expect(MailEvent.last.event_type).to eq("suppression.added")
      expect(MailEvent.last.recipient).to eq("hello@bible-together.org")
    end
  end

  describe "routine delivery events" do
    let(:payload) do
      { type: "email.delivered", created_at: "2026-08-06T09:41:12.126Z",
        data: { email_id: "abc", to: [ "hello@bible-together.org" ] } }.to_json
    end

    it "acknowledges without recording, so Svix stops retrying" do
      expect {
        post "/webhooks/resend", params: payload, headers: signed_headers(payload)
      }.not_to change(MailEvent, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "signature rejection" do
    it "returns 401 and records nothing when the signature is wrong" do
      headers = signed_headers(bounce_payload,
                               secret_override: "whsec_#{Base64.strict_encode64('wrong-key')}")

      expect {
        post "/webhooks/resend", params: bounce_payload, headers: headers
      }.not_to change(MailEvent, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the body was tampered with after signing" do
      headers = signed_headers(bounce_payload)

      post "/webhooks/resend", params: bounce_payload.sub("Permanent", "Transient"), headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the svix headers are missing entirely" do
      expect {
        post "/webhooks/resend", params: bounce_payload,
                                 headers: { "CONTENT_TYPE" => "application/json" }
      }.not_to change(MailEvent, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a replayed request outside the tolerance window" do
      stale = Time.current.to_i - (Resend::WebhookSignature::TOLERANCE.to_i + 60)

      post "/webhooks/resend", params: bounce_payload,
                               headers: signed_headers(bounce_payload, timestamp: stale)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "retries" do
    # Svix redelivers on any non-2xx, and can redeliver on success too.
    it "is idempotent — a redelivered event does not double-record" do
      headers = signed_headers(bounce_payload)
      post "/webhooks/resend", params: bounce_payload, headers: headers

      expect {
        post "/webhooks/resend", params: bounce_payload, headers: headers
      }.not_to change(MailEvent, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "malformed input" do
    it "returns 400 for a body that is not JSON" do
      body = "this is not json"

      post "/webhooks/resend", params: body, headers: signed_headers(body)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "misconfiguration" do
    # An unset secret must never degrade into accepting unverified
    # webhooks. Failing loudly also makes Svix retry, which keeps the
    # misconfiguration visible instead of silently dropping events.
    it "returns 500 when no signing secret is configured" do
      allow(Rails.application.credentials)
        .to receive(:dig).with(:resend, :webhook_secret).and_return(nil)

      expect {
        post "/webhooks/resend", params: bounce_payload, headers: signed_headers(bounce_payload)
      }.not_to change(MailEvent, :count)

      expect(response).to have_http_status(:internal_server_error)
    end
  end

  # Regression guard: ApplicationController applies `allow_browser
  # versions: :modern`, plus set_locale and importmap etag logic, none of
  # which belong on a machine-to-machine endpoint. If this controller is
  # ever re-parented to ApplicationController, a webhook with no
  # User-Agent risks a 406 and events go silently undelivered.
  it "accepts a request with no User-Agent" do
    post "/webhooks/resend", params: bounce_payload,
                             headers: signed_headers(bounce_payload).merge("HTTP_USER_AGENT" => nil)

    expect(response).to have_http_status(:ok)
  end

  it "does not require a CSRF token" do
    ActionController::Base.allow_forgery_protection = true

    post "/webhooks/resend", params: bounce_payload, headers: signed_headers(bounce_payload)

    expect(response).to have_http_status(:ok)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
