class CreateContactMessages < ActiveRecord::Migration[8.1]
  def change
    # Public contact-form submissions from /contact. The row is the
    # record of truth; the notification email to hello@ is best-effort.
    # Before this table existed the email *was* the transport, so when
    # Resend suppressed the recipient after a bounce every submission
    # was lost silently. Name is nullable (the form allows a blank name
    # and the mailer falls back to the email address); email and message
    # are required at both the model and the database.
    create_table :contact_messages do |t|
      t.string :name
      t.string :email, null: false
      t.text :message, null: false
      t.timestamps
    end
  end
end
