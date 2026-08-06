class ContactsController < ApplicationController
  def new
    @contact = ContactMessage.new
  end

  def create
    @contact = ContactMessage.new(contact_params)

    if @contact.save
      notify(@contact)
      redirect_to contact_path, notice: t("contact.success")
    else
      flash.now[:alert] = t("contact.error")
      render :new, status: :unprocessable_content
    end
  end

  private

  def contact_params
    params.require(:contact_message).permit(:name, :email, :message)
  end

  # Notification only — the row above is what we actually keep. Enqueue
  # happens after the write and cannot take the submission down with it:
  # a failure here (queue backend unreachable, serialization error) gets
  # logged instead of raised. SMTP failures land in the job rather than
  # this request, and Resend accepts-then-suppresses mail to a bounced
  # recipient without erroring at all, so delivery was never something
  # this action could confirm.
  def notify(contact)
    ContactMailer.contact_message(
      name: contact.name,
      email: contact.email,
      message: contact.message
    ).deliver_later
  rescue StandardError => e
    Rails.logger.error("contact notification failed for ContactMessage ##{contact.id}: #{e.class}: #{e.message}")
  end
end
