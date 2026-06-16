require "rails_helper"

RSpec.describe Seeds::PublicNotes do
  let!(:translation) { create(:translation, :kjv) }
  let!(:book_john)   { create(:book, :john, translation: translation) }
  let!(:chapter)     { create(:chapter, book: book_john, number: 3) }

  before do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.John.3.16")
  end

  it "creates public notes when KJV verses exist" do
    expect { described_class.call }.to change(Note.public_visible, :count).by_at_least(1)
  end

  it "is idempotent on re-run" do
    described_class.call
    expect { described_class.call }.not_to change(Note, :count)
  end

  it "skips gracefully when KJV is missing" do
    allow(Translation).to receive(:find_by).with(code: "KJV").and_return(nil)
    expect { described_class.call }.not_to change(Note, :count)
  end
end
