require "rails_helper"

RSpec.describe "Memberships", type: :request do
  let(:owner)   { create(:user) }
  let(:outsider) { create(:user, email: "friend@bible-together.test") }
  let(:group)   { create(:group, owner: owner) }

  describe "DELETE /studies/:group_id/memberships/:id" do
    let(:member) { create(:user) }
    let!(:membership) { create(:membership, user: member, group: group, role: :member) }

    it "lets the owner remove a member" do
      sign_in owner
      expect {
        delete "/studies/#{group.id}/memberships/#{membership.id}"
      }.to change { group.members.include?(member) }.from(true).to(false)
    end

    it "404s for non-owners trying to remove someone else" do
      third = create(:user)
      create(:membership, user: third, group: group, role: :member)
      sign_in third
      delete "/studies/#{group.id}/memberships/#{membership.id}"
      expect(response).to have_http_status(:not_found)
      expect(Membership.exists?(membership.id)).to be true
    end
  end
end
