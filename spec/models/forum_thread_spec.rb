require "rails_helper"

RSpec.describe ForumThread, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:forum_posts).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }

  describe ".visible" do
    it "excludes hidden threads" do
      visible = create(:forum_thread)
      hidden  = create(:forum_thread, hidden_at: Time.current)
      expect(ForumThread.visible).to include(visible)
      expect(ForumThread.visible).not_to include(hidden)
    end
  end

  describe "a new post" do
    it "stamps the thread's last_posted_at" do
      thread = create(:forum_thread)
      expect { create(:forum_post, forum_thread: thread) }
        .to change { thread.reload.last_posted_at }
    end
  end
end
