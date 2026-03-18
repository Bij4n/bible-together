require "rails_helper"

RSpec.describe "Comment broadcasts" do
  let(:author)    { create(:user) }
  let(:commenter) { create(:user) }
  let!(:translation) { create(:translation, :kjv) }
  let!(:book)    { create(:book, :john, translation: translation) }
  let!(:chapter) { create(:chapter, book: book, number: 3) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 16,
                   body_text: "For God so loved the world",
                   body_html: "For God so loved the world",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.John.3.16")
  end
  let(:group) { create(:group, owner: author) }

  before { create(:membership, user: commenter, group: group, role: :member) }

  def stream_name_for(group, translation_code = "KJV", book_osis = "John", chapter_number = 3)
    Turbo::StreamsChannel.send(:stream_name_from,
                               [ group, "bible", translation_code, book_osis, chapter_number ])
  end

  def shared_group_note
    highlight = create(:highlight, user: author, translation: translation,
                                   osis_ref: "Bible.KJV.John.3.16", color: "gold")
    note = create(:note, user: author, body: "<p>Body</p>", visibility: :shared_groups)
    create(:highlight_note, highlight: highlight, note: note)
    create(:note_share, note: note, shareable: group)
    note
  end

  it "broadcasts append to the group channel when a comment is created on a group-shared note" do
    note = shared_group_note

    expect {
      Comment.create!(note: note, user: commenter, body: "Great catch")
    }.to have_broadcasted_to(stream_name_for(group))
       .from_channel(Turbo::StreamsChannel)
       .at_least(:once)
  end

  it "doesn't broadcast comments on notes that aren't shared with any group" do
    private_note = create(:note, user: author, visibility: :private_note)

    expect {
      Comment.create!(note: private_note, user: author, body: "Just me")
    }.not_to have_broadcasted_to(stream_name_for(group))
  end

  it "broadcasts remove when a comment is destroyed" do
    note = shared_group_note
    comment = Comment.create!(note: note, user: commenter, body: "Scratch that")

    expect {
      comment.destroy!
    }.to have_broadcasted_to(stream_name_for(group))
       .from_channel(Turbo::StreamsChannel)
       .at_least(:once)
  end

  it "broadcasts to each group a note is shared with" do
    other_group = create(:group, owner: author)
    note = shared_group_note
    create(:note_share, note: note, shareable: other_group)

    expect {
      Comment.create!(note: note, user: commenter, body: "To both")
    }.to have_broadcasted_to(stream_name_for(other_group))
       .from_channel(Turbo::StreamsChannel)
       .at_least(:once)
  end
end
