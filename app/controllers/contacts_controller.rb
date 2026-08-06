class ContactsController < ApplicationController
  # A bot submission is what hard-bounced the notification address and
  # got it onto Resend's suppression list, which killed the whole channel
  # silently. Two cheap gates guard the form: the honeypot below, and a
  # per-IP cap here. The limiter counts against the controller cache
  # store — Solid Cache in production, so the count is shared across web
  # processes rather than per-Puma-worker.
  rate_limit to: 5, within: 1.hour, only: :create, with: :contact_rate_limited

  def new
    @contact = ContactMessage.new
  end

  def create
    return drop_as_spam if params[:website].present?

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

  # Honeypot-tripped submissions get the same response a human gets —
  # nothing written, nothing sent. An obvious rejection would just teach
  # the bot to retry with the field cleared.
  def drop_as_spam
    redirect_to contact_path, notice: t("contact.success")
  end

  # Re-renders the form rather than a bare 429 so a real person who hit
  # the cap sees an explanation and keeps what they typed.
  def contact_rate_limited
    @contact = ContactMessage.new(params.fetch(:contact_message, {}).permit(:name, :email, :message))
    flash.now[:alert] = t("contact.rate_limited")
    render :new, status: :too_many_requests
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
