require "rails_helper"

RSpec.describe "Comment notifications", type: :request do
  let(:author)    { create(:user, email_on_comment: true) }
  let(:commenter) { create(:user) }
  let(:note)      { create(:note, :public_note, user: author) }

  it "emails the note author when someone else comments" do
    sign_in commenter
    expect {
      post comments_path, params: { comment: { note_id: note.id, body: "Amen" } }
    }.to have_enqueued_mail(CommentMailer, :new_comment)
  end

  it "does not email when the author has opted out" do
    author.update!(email_on_comment: false)
    sign_in commenter
    expect {
      post comments_path, params: { comment: { note_id: note.id, body: "Amen" } }
    }.not_to have_enqueued_mail(CommentMailer, :new_comment)
  end

  it "does not email when commenting on your own note" do
    sign_in author
    expect {
      post comments_path, params: { comment: { note_id: note.id, body: "Self" } }
    }.not_to have_enqueued_mail(CommentMailer, :new_comment)
  end
end
