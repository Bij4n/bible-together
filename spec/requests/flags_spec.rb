require "rails_helper"

RSpec.describe "Flags", type: :request do
  let(:reporter) { create(:user) }
  let(:author)   { create(:user) }

  describe "POST /flags" do
    it "requires sign-in" do
      note = create(:note, user: author, visibility: :public_note)
      post "/flags", params: { flag: { flaggable_type: "Note", flaggable_id: note.id, reason: "spam" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    context "when signed in" do
      before { sign_in reporter }

      it "creates a flag on a visible note" do
        note = create(:note, user: author, visibility: :public_note)
        expect {
          post "/flags", params: { flag: { flaggable_type: "Note", flaggable_id: note.id, reason: "inappropriate", details: "link-bait" } }
        }.to change(Flag, :count).by(1)
        flag = Flag.last
        expect(flag.user).to eq(reporter)
        expect(flag.flaggable).to eq(note)
        expect(flag.reason).to eq("inappropriate")
      end

      it "creates a flag on a visible comment" do
        note = create(:note, user: author, visibility: :public_note)
        comment = create(:comment, note: note, user: author, body: "hey")
        expect {
          post "/flags", params: { flag: { flaggable_type: "Comment", flaggable_id: comment.id, reason: "harassment" } }
        }.to change(Flag, :count).by(1)
      end

      it "404s when the note isn't visible" do
        private_note = create(:note, user: author, visibility: :private_note)
        post "/flags", params: { flag: { flaggable_type: "Note", flaggable_id: private_note.id, reason: "spam" } }
        expect(response).to have_http_status(:not_found)
      end

      it "rejects an invalid reason" do
        note = create(:note, user: author, visibility: :public_note)
        post "/flags", params: { flag: { flaggable_type: "Note", flaggable_id: note.id, reason: "banana" } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "is silent on duplicate flags (already-flagged by this user)" do
        note = create(:note, user: author, visibility: :public_note)
        create(:flag, user: reporter, flaggable: note)
        expect {
          post "/flags", params: { flag: { flaggable_type: "Note", flaggable_id: note.id, reason: "spam" } }
        }.not_to change(Flag, :count)
        expect(response).to have_http_status(:ok)
      end

      it "rejects unknown flaggable_type" do
        post "/flags", params: { flag: { flaggable_type: "User", flaggable_id: author.id, reason: "spam" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
