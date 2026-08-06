class CreateMailEvents < ActiveRecord::Migration[8.1]
  def change
    # Failure events from Resend's webhook. Before this existed there was
    # no way to learn that outbound mail had stopped arriving: Resend
    # accepts the SMTP handoff and drops suppressed mail afterward, so
    # nothing raises and nothing logs. The Aug 2026 contact-form outage
    # ran for three days on exactly that blind spot.
    #
    # svix_id is the idempotency key — Svix redelivers on any non-2xx, and
    # may redeliver on success — so it carries a unique index and ingestion
    # relies on it rather than on a read-then-write check.
    #
    # payload keeps the raw event because the shapes of the suppression.*
    # events aren't documented; better to store everything than to trust a
    # field mapping written against a bounce example.
    create_table :mail_events do |t|
      t.string :event_type, null: false
      t.string :svix_id, null: false
      t.string :email_id
      t.string :recipient
      t.string :subject
      t.text :reason
      t.datetime :occurred_at
      t.jsonb :payload, default: {}, null: false
      t.timestamps
    end

    add_index :mail_events, :svix_id, unique: true
    # Supports "what has gone wrong lately" and "is this address failing",
    # the two questions this table exists to answer.
    add_index :mail_events, [ :event_type, :occurred_at ]
    add_index :mail_events, :recipient
  end
end
