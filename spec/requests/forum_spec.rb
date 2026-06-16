require "rails_helper"

RSpec.describe "Forum", type: :request do
  let(:user) { create(:user) }

  describe "GET /forum" do
    it "is public and lists visible threads" do
      create(:forum_thread, title: "Welcome to the forum")
      get "/forum"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to the forum")
    end
  end

  describe "GET /forum/:id" do
    it "shows a visible thread with its posts" do
      thread = create(:forum_thread)
      create(:forum_post, forum_thread: thread, body: "First message")
      get forum_thread_path(thread)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("First message")
    end

    it "404s a hidden thread" do
      thread = create(:forum_thread, hidden_at: Time.current)
      get forum_thread_path(thread)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "creating a thread" do
    it "requires sign in" do
      post forum_threads_path, params: { forum_thread: { title: "Hi", body: "Hello" } }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a thread with a first post when signed in" do
      sign_in user
      expect {
        post forum_threads_path, params: { forum_thread: { title: "My topic", body: "Opening message" } }
      }.to change(ForumThread, :count).by(1).and(change(ForumPost, :count).by(1))
      expect(response).to redirect_to(forum_thread_path(ForumThread.last))
    end

    it "rejects a blank body" do
      sign_in user
      post forum_threads_path, params: { forum_thread: { title: "No body", body: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(ForumThread.count).to eq(0)
    end
  end

  describe "replying" do
    it "lets a signed-in user reply" do
      thread = create(:forum_thread)
      sign_in user
      expect {
        post forum_thread_forum_posts_path(thread), params: { forum_post: { body: "A reply" } }
      }.to change(ForumPost, :count).by(1)
    end
  end

  describe "moderation" do
    let(:admin) { create(:user, admin: true) }

    it "lets an admin hide a thread" do
      thread = create(:forum_thread)
      sign_in admin
      patch hide_forum_thread_path(thread)
      expect(thread.reload.hidden_at).to be_present
    end

    it "forbids a non-admin from hiding" do
      thread = create(:forum_thread)
      sign_in user
      patch hide_forum_thread_path(thread)
      expect(thread.reload.hidden_at).to be_nil
    end
  end
end
