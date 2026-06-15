require "rails_helper"

RSpec.describe "Groups", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "legacy /groups redirects" do
    it "301s /groups to /studies" do
      get "/groups"
      expect(response).to redirect_to("/studies")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "301s nested /groups paths to /studies" do
      get "/groups/discover"
      expect(response).to redirect_to("/studies/discover")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /studies" do
    it "requires sign-in" do
      get "/studies"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "lists the user's groups" do
      sign_in user
      group = create(:group, owner: user, name: "My Study")
      not_mine = create(:group, owner: other_user, name: "Theirs")

      get "/studies"
      expect(response.body).to include("My Study")
      expect(response.body).not_to include("Theirs")
      _ = not_mine
    end
  end

  describe "POST /studies" do
    before { sign_in user }

    it "creates a group with the current user as owner" do
      expect {
        post "/studies", params: { group: { name: "Sunday Study", privacy: "invite_only" } }
      }.to change(Group, :count).by(1)
      group = Group.last
      expect(group.owner).to eq(user)
      expect(group.members).to include(user)
    end

    it "rejects blank name" do
      post "/studies", params: { group: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /studies/:id" do
    let(:group) { create(:group, owner: user) }

    it "requires membership" do
      sign_in other_user
      get "/studies/#{group.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "shows the group to its owner" do
      sign_in user
      get "/studies/#{group.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(group.name)
    end

    it "shows the group to a member" do
      sign_in other_user
      create(:membership, user: other_user, group: group, role: :member)
      get "/studies/#{group.id}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /studies/:id" do
    let(:group) { create(:group, owner: user) }

    it "allows the owner to update" do
      sign_in user
      patch "/studies/#{group.id}", params: { group: { name: "Renamed" } }
      expect(group.reload.name).to eq("Renamed")
    end

    it "404s for non-owner members" do
      sign_in other_user
      create(:membership, user: other_user, group: group, role: :member)
      patch "/studies/#{group.id}", params: { group: { name: "Hostile" } }
      expect(response).to have_http_status(:not_found)
      expect(group.reload.name).not_to eq("Hostile")
    end
  end

  describe "DELETE /studies/:id" do
    let!(:group) { create(:group, owner: user) }

    it "allows the owner to destroy" do
      sign_in user
      expect {
        delete "/studies/#{group.id}"
      }.to change(Group, :count).by(-1)
    end

    it "404s for non-owners" do
      sign_in other_user
      create(:membership, user: other_user, group: group, role: :member)
      delete "/studies/#{group.id}"
      expect(response).to have_http_status(:not_found)
      expect(Group.exists?(group.id)).to be true
    end
  end

  describe "POST /studies/join" do
    let!(:group) { create(:group, :with_invitation_code, owner: other_user, invitation_code: "JOIN42") }

    before { sign_in user }

    it "adds the user as a member when the code matches" do
      expect {
        post "/studies/join", params: { invitation_code: "JOIN42" }
      }.to change { group.members.include?(user) }.from(false).to(true)
      expect(response).to redirect_to(group_path(group))
    end

    it "rejects unknown codes" do
      post "/studies/join", params: { invitation_code: "NOPE99" }
      expect(response).to redirect_to(groups_path)
      expect(flash[:alert]).to be_present
    end

    it "is idempotent when the user is already a member" do
      create(:membership, user: user, group: group, role: :member)
      expect {
        post "/studies/join", params: { invitation_code: "JOIN42" }
      }.not_to change(Membership, :count)
      expect(response).to redirect_to(group_path(group))
    end
  end

  describe "DELETE /studies/:id/leave" do
    let(:group) { create(:group, owner: other_user) }
    before do
      create(:membership, user: user, group: group, role: :member)
      sign_in user
    end

    it "removes the user's membership" do
      expect {
        delete "/studies/#{group.id}/leave"
      }.to change { group.members.include?(user) }.from(true).to(false)
    end

    it "blocks the last owner from leaving" do
      sign_out user
      sign_in other_user
      delete "/studies/#{group.id}/leave"
      expect(response).to redirect_to(group_path(group))
      expect(flash[:alert]).to be_present
      expect(group.members).to include(other_user)
    end
  end
end
