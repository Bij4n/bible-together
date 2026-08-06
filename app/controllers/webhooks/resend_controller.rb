module Webhooks
  # Ingests Resend delivery-failure events.
  #
  # Inherits ActionController::Base rather than ApplicationController
  # deliberately. ApplicationController carries `allow_browser versions:
  # :modern`, a set_locale before_action that reads the session, and
  # importmap etag logic — none of which apply to a machine-to-machine
  # POST, and the browser gate is a 406 risk for a request that sends no
  # User-Agent. A spec pins that behaviour so re-parenting this controller
  # can't silently start dropping events.
  class ResendController < ActionController::Base
    skip_forgery_protection

    def create
      if signing_secret.blank?
        # Never degrade to accepting unverified webhooks. Failing loudly
        # also makes Svix retry, which keeps the misconfiguration visible
        # instead of quietly discarding events.
        Rails.logger.error("resend webhook: no signing secret configured, refusing to process")
        return head :internal_server_error
      end

      return head :unauthorized unless verified?

      event = JSON.parse(request.raw_post)
      record(event) if MailEvent.records?(event["type"])

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def signing_secret
      Rails.application.credentials.dig(:resend, :webhook_secret)
    end

    # Fully qualified: a bare `Resend::` would be resolved relative to
    # `Webhooks::` first, which is a trap given this class is ResendController.
    def verified?
      ::Resend::WebhookSignature.new(signing_secret).valid?(
        payload: request.raw_post,
        svix_id: request.headers["svix-id"],
        svix_timestamp: request.headers["svix-timestamp"],
        svix_signature: request.headers["svix-signature"]
      )
    end

    # insert_all with unique_by makes ingestion idempotent in one statement
    # (Postgres ON CONFLICT DO NOTHING). Svix redelivers on any non-2xx and
    # may redeliver on success, and a read-then-write check would still
    # race two concurrent redeliveries.
    def record(event)
      attributes = extract(event)
      inserted = MailEvent.insert_all([ attributes ], unique_by: :svix_id)

      return if inserted.empty?

      log(attributes)
    end

    def extract(event)
      data = event["data"] || {}
      bounce = data["bounce"] || {}
      now = Time.current

      {
        event_type: event["type"],
        svix_id: request.headers["svix-id"],
        email_id: data["email_id"],
        # Failure events carry data.to; the suppression.* events aren't
        # documented, so fall back to a bare address field.
        recipient: Array(data["to"]).first.presence || data["email"],
        subject: data["subject"],
        reason: [ bounce["type"], bounce["subType"], bounce["message"] ].compact_blank.join(" / ").presence,
        occurred_at: event["created_at"],
        payload: event,
        created_at: now,
        updated_at: now
      }
    end

    def log(attributes)
      message = "resend webhook: #{attributes[:event_type]} " \
                "recipient=#{attributes[:recipient].inspect} " \
                "reason=#{attributes[:reason].inspect}"

      if MailEvent::FAILURE_TYPES.include?(attributes[:event_type])
        Rails.logger.error(message)
      else
        Rails.logger.info(message)
      end
    end
  end
end
