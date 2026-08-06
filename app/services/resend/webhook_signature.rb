module Resend
  # Verifies Resend webhook signatures. Resend delegates webhook signing to
  # Svix, so this implements Svix's documented manual-verification
  # algorithm rather than adding the svix gem for one HMAC:
  #
  #   1. signed content is "<svix-id>.<svix-timestamp>.<raw body>"
  #   2. the key is the base64-decoded part of a whsec_-prefixed secret
  #   3. HMAC-SHA256, base64-encoded
  #   4. the svix-signature header is space-delimited "v1,<sig>" pairs
  #   5. compared in constant time
  #
  # Verification is all-or-nothing on purpose: every failure path returns
  # false rather than raising, and a missing secret returns false too, so a
  # configuration mistake can never be mistaken for a valid signature.
  class WebhookSignature
    # Svix publishes no tolerance window; their own SDKs use five minutes.
    # This bounds replay of a captured request.
    TOLERANCE = 5.minutes

    SECRET_PREFIX = "whsec_".freeze
    SUPPORTED_VERSION = "v1".freeze

    def initialize(secret)
      @secret = secret.to_s
    end

    def valid?(payload:, svix_id:, svix_timestamp:, svix_signature:)
      return false if @secret.blank?
      return false if payload.nil?
      return false if svix_id.blank? || svix_timestamp.blank? || svix_signature.blank?
      return false unless within_tolerance?(svix_timestamp)

      expected = digest("#{svix_id}.#{svix_timestamp}.#{payload}")

      offered(svix_signature).any? do |candidate|
        ActiveSupport::SecurityUtils.secure_compare(candidate, expected)
      end
    end

    private

    # Lenient decode rather than strict: a malformed secret should make
    # verification fail, not raise.
    def key
      Base64.decode64(@secret.delete_prefix(SECRET_PREFIX))
    end

    def digest(signed_content)
      Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, signed_content))
    end

    # Svix may send several signatures during a secret rotation. Versions
    # other than v1 are ignored rather than guessed at.
    def offered(header)
      header.to_s.split(" ").filter_map do |pair|
        version, signature = pair.split(",", 2)
        signature if version == SUPPORTED_VERSION && signature.present?
      end
    end

    def within_tolerance?(timestamp)
      seconds = Integer(timestamp, exception: false)
      return false if seconds.nil?

      (Time.current.to_i - seconds).abs <= TOLERANCE.to_i
    end
  end
end
