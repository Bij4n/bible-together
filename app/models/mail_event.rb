# A noteworthy delivery event from Resend, recorded via webhook so that
# outbound mail failing is observable. Routine events (sent, delivered,
# opened, clicked) are acknowledged but never stored — this table exists to
# surface problems, not to mirror Resend's whole stream.
class MailEvent < ApplicationRecord
  # email.suppressed and suppression.added are the two that matter most
  # here: a suppressed recipient is what silently swallowed every contact
  # form submission for three days in Aug 2026.
  FAILURE_TYPES = %w[
    email.bounced
    email.complained
    email.failed
    email.suppressed
  ].freeze

  OTHER_RECORDED_TYPES = %w[
    email.delivery_delayed
    suppression.added
    suppression.removed
  ].freeze

  RECORDED_TYPES = (FAILURE_TYPES + OTHER_RECORDED_TYPES).freeze

  validates :event_type, presence: true
  validates :svix_id, presence: true, uniqueness: true

  scope :recent_first, -> { order(occurred_at: :desc) }
  scope :failures, -> { where(event_type: FAILURE_TYPES) }

  def self.records?(event_type)
    RECORDED_TYPES.include?(event_type)
  end

  def failure?
    FAILURE_TYPES.include?(event_type)
  end
end
