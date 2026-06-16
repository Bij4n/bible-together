# Idempotent dev/demo public notes for the homepage community section.
# Requires KJV import (bin/rails bible:import[kjv]) so verse rows exist.
module Seeds
  class PublicNotes
    SEED_PASSWORD = "seed-public-notes-only"

    ENTRIES = [
      {
        email: "seed.apollos@bible-together.dev",
        display_name: "Apollos",
        osis_ref: "Bible.KJV.John.3.16",
        color: "yellow",
        body: "<p>The hinge of the gospel: love measured not in sentiment but in sacrifice.</p>"
      },
      {
        email: "seed.priscilla@bible-together.dev",
        display_name: "Priscilla",
        osis_ref: "Bible.KJV.Psa.23.1",
        color: "green",
        body: "<p>Shepherd language lands differently when you feel un-led. Rest is the first gift.</p>"
      },
      {
        email: "seed.lydia@bible-together.dev",
        display_name: "Lydia",
        osis_ref: "Bible.KJV.Rom.8.28",
        color: "blue",
        body: "<p>Not a promise that everything is good, only that nothing is wasted in God's hands.</p>"
      },
      {
        email: "seed.phoebe@bible-together.dev",
        display_name: "Phoebe",
        osis_ref: "Bible.KJV.Phil.4.6",
        color: "rose",
        body: "<p>Prayer before petition: bring the anxiety, then ask. The order matters.</p>"
      },
      {
        email: "seed.timothy@bible-together.dev",
        display_name: "Timothy",
        osis_ref: "Bible.KJV.Gen.1.2",
        color: "yellow",
        body: "<p>Formless and void, but the Spirit is already hovering. Chaos is not the last word.</p>"
      }
    ].freeze

    def self.call
      new.call
    end

    def call
      translation = Translation.find_by(code: "KJV")
      unless translation
        puts "Seeds::PublicNotes skipped: import KJV first (bin/rails bible:import[kjv])"
        return
      end

      created = 0
      ENTRIES.each do |entry|
        next unless verse_exists?(entry[:osis_ref])

        user = find_or_create_user(entry)
        highlight = find_or_create_highlight(user, translation, entry)
        find_or_create_note(user, highlight, entry)
        created += 1
      end

      puts "Seeds::PublicNotes ensured #{created} public note(s)"
    end

    private

    def verse_exists?(osis_ref)
      Verse.exists?(osis_ref: osis_ref)
    end

    def find_or_create_user(entry)
      User.find_or_create_by!(email: entry[:email]) do |user|
        user.password = SEED_PASSWORD
        user.password_confirmation = SEED_PASSWORD
        user.display_name = entry[:display_name]
      end.tap do |user|
        user.update!(display_name: entry[:display_name]) if user.display_name != entry[:display_name]
      end
    end

    def find_or_create_highlight(user, translation, entry)
      user.highlights.find_or_create_by!(
        translation: translation,
        osis_ref: entry[:osis_ref],
        color: entry[:color]
      )
    end

    def find_or_create_note(user, highlight, entry)
      note = highlight.notes.first
      return sync_note(note, entry) if note

      note = user.notes.create!(visibility: :public_note, body: entry[:body])
      HighlightNote.create!(highlight: highlight, note: note)
      note
    end

    def sync_note(note, entry)
      note.update!(visibility: :public_note, body: entry[:body]) if note.body.to_s != entry[:body]
      note
    end
  end
end
