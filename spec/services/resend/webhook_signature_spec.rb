require "rails_helper"

RSpec.describe Resend::WebhookSignature do
  # The secret and signature below were produced independently with
  # openssl, not by this class, so these examples verify the documented
  # Svix algorithm rather than agreeing with our own implementation:
  #
  #   printf '%s' 'msg_2abc.1754467200.{"type":"email.bounced"}' \
  #     | openssl dgst -sha256 -mac HMAC \
  #         -macopt 'key:bible-together-webhook-test-key!' -binary \
  #     | base64
  #
  let(:secret)    { "whsec_YmlibGUtdG9nZXRoZXItd2ViaG9vay10ZXN0LWtleSE=" }
  let(:svix_id)   { "msg_2abc" }
  let(:timestamp) { "1754467200" }
  let(:payload)   { '{"type":"email.bounced"}' }
  let(:signature) { "v1,hfOuos+nSa+wU+y6ZL62p8MrekbZGRuVz8m8TTScgoI=" }
  let(:signed_at) { Time.zone.at(timestamp.to_i) }

  subject(:verifier) { described_class.new(secret) }

  def verify(overrides = {})
    args = {
      payload: payload,
      svix_id: svix_id,
      svix_timestamp: timestamp,
      svix_signature: signature
    }.merge(overrides)

    verifier.valid?(**args)
  end

  it "accepts a signature matching the documented algorithm" do
    travel_to(signed_at) { expect(verify).to be(true) }
  end

  it "accepts a header carrying several space-delimited signatures" do
    travel_to(signed_at) do
      expect(verify(svix_signature: "v1,Y7NvZXRoaXNpc3dyb25n= #{signature}")).to be(true)
    end
  end

  it "ignores signature versions it does not understand" do
    travel_to(signed_at) do
      expect(verify(svix_signature: signature.sub("v1,", "v2,"))).to be(false)
    end
  end

  it "rejects a tampered payload" do
    travel_to(signed_at) do
      expect(verify(payload: '{"type":"email.delivered"}')).to be(false)
    end
  end

  it "rejects a mismatched svix id" do
    travel_to(signed_at) { expect(verify(svix_id: "msg_other")).to be(false) }
  end

  it "rejects a signature made with a different secret" do
    other = described_class.new("whsec_#{Base64.strict_encode64('not-the-key')}")

    travel_to(signed_at) do
      expect(
        other.valid?(payload: payload, svix_id: svix_id,
                     svix_timestamp: timestamp, svix_signature: signature)
      ).to be(false)
    end
  end

  # Replay protection: a captured-and-resent request stops verifying once
  # it falls outside the tolerance window.
  it "rejects a timestamp past the tolerance window" do
    travel_to(signed_at + described_class::TOLERANCE + 1.second) do
      expect(verify).to be(false)
    end
  end

  it "accepts a timestamp inside the tolerance window" do
    travel_to(signed_at + described_class::TOLERANCE - 1.second) do
      expect(verify).to be(true)
    end
  end

  it "rejects a timestamp from the future beyond tolerance (clock skew bound)" do
    travel_to(signed_at - described_class::TOLERANCE - 1.second) do
      expect(verify).to be(false)
    end
  end

  it "rejects a non-numeric timestamp" do
    travel_to(signed_at) { expect(verify(svix_timestamp: "not-a-number")).to be(false) }
  end

  it "rejects blank headers" do
    travel_to(signed_at) do
      expect(verify(svix_signature: "")).to be(false)
      expect(verify(svix_id: "")).to be(false)
      expect(verify(svix_timestamp: "")).to be(false)
    end
  end

  # Never verify against an unconfigured secret — that would turn a
  # missing credential into an open endpoint.
  it "refuses to verify when no secret is configured" do
    travel_to(signed_at) do
      expect(
        described_class.new(nil).valid?(payload: payload, svix_id: svix_id,
                                        svix_timestamp: timestamp, svix_signature: signature)
      ).to be(false)
    end
  end
end
