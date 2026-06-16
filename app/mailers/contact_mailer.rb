class ContactMailer < ApplicationMailer
  # Inbound address for public contact-form submissions. From stays the
  # verified SMTP sender (ApplicationMailer default); reply_to is set to
  # the submitter so a reply goes straight back to them.
  CONTACT_ADDRESS = "hello@bible-together.org".freeze

  def contact_message(name:, email:, message:)
    @name = name.presence || email
    @email = email
    @message = message

    mail(
      to: CONTACT_ADDRESS,
      reply_to: email,
      subject: "Contact form — #{@name}"
    )
  end
end
