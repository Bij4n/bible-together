# A public contact-form submission, persisted before the notification
# email is enqueued. Replaced the non-persisted ContactForm object: the
# email used to be the only transport, so a suppressed or bounced
# recipient destroyed the message with no trace.
class ContactMessage < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { maximum: 5000 }
  validates :name, length: { maximum: 120 }
end
