# Non-persisted form object for the public contact page. Carries the
# sender's details to ContactMailer; no database row is created.
class ContactForm
  include ActiveModel::Model

  attr_accessor :name, :email, :message

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { maximum: 5000 }
  validates :name, length: { maximum: 120 }
end
