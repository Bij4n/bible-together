require "rails_helper"

RSpec.describe "Follows", type: :request do
  let(:user)   { create(:user) }
  let(:author) { create(:user, display_name: "Apollos") }

  describe "POST /authors/:author_id/follow" do
    it "requires sign-in" do
      post author_follow_path(author)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "follows the author and redirects back to their page" do
      sign_in user
      expect {
        post author_follow_path(author)
      }.to change(Follow, :count).by(1)
      expect(user.reload.following?(author)).to be true
      expect(response).to redirect_to(author_path(author))
    end

    it "is idempotent" do
      sign_in user
      user.follow!(author)
      expect {
        post author_follow_path(author)
      }.not_to change(Follow, :count)
      expect(response).to redirect_to(author_path(author))
    end

    it "404s on self-follow attempts" do
      sign_in user
      post author_follow_path(user)
      expect(response).to have_http_status(:not_found)
    end

    it "404s on unknown authors" do
      sign_in user
      post "/authors/999999/follow"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /authors/:author_id/follow" do
    it "unfollows and redirects back" do
      sign_in user
      user.follow!(author)
      expect {
        delete author_follow_path(author)
      }.to change(Follow, :count).by(-1)
      expect(response).to redirect_to(author_path(author))
    end

    it "is a no-op when not following" do
      sign_in user
      expect {
        delete author_follow_path(author)
      }.not_to change(Follow, :count)
      expect(response).to redirect_to(author_path(author))
    end
  end
end
