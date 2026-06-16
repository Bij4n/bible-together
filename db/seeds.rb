# Idempotent seeds — safe to re-run in development.
require Rails.root.join("lib/seeds/public_notes")
Seeds::PublicNotes.call
