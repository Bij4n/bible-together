require "rails_helper"

RSpec.describe "Group administration", type: :request do
  let(:owner)  { create(:user) }
  let(:admin)  { create(:user) }
  let(:member) { create(:user) }
  let(:group)  { create(:group, owner: owner) }

  before do
    create(:membership, user: admin, group: group, role: :admin)
    create(:membership, user: member, group: group, role: :member)
  end

  describe "editing the group" do
    it "lets an admin update group details" do
      sign_in admin
      patch group_path(group), params: { group: { description: "Updated by admin" } }
      expect(group.reload.description).to eq("Updated by admin")
    end

    it "forbids a plain member from editing" do
      sign_in member
      patch group_path(group), params: { group: { description: "Nope" } }
      expect(group.reload.description).not_to eq("Nope")
    end
  end

  describe "destroying the group" do
    it "lets the owner destroy it" do
      sign_in owner
      expect { delete group_path(group) }.to change(Group, :count).by(-1)
    end

    it "forbids an admin from destroying it" do
      sign_in admin
      expect { delete group_path(group) }.not_to change(Group, :count)
    end
  end

  describe "inviting members" do
    it "lets an admin send an invitation" do
      sign_in admin
      expect {
        post group_invitations_path(group), params: { group_invitation: { email: "new@example.com" } }
      }.to change(GroupInvitation, :count).by(1)
    end

    it "forbids a plain member from inviting" do
      sign_in member
      post group_invitations_path(group), params: { group_invitation: { email: "x@example.com" } }
      expect(GroupInvitation.count).to eq(0)
    end
  end

  describe "managing roles" do
    it "lets the owner promote a member to admin" do
      sign_in owner
      m = group.memberships.find_by(user: member)
      patch group_membership_path(group, m), params: { membership: { role: "admin" } }
      expect(m.reload.role).to eq("admin")
    end

    it "forbids an admin from promoting members" do
      sign_in admin
      m = group.memberships.find_by(user: member)
      patch group_membership_path(group, m), params: { membership: { role: "admin" } }
      expect(m.reload.role).to eq("member")
    end
  end

  describe "removing members" do
    it "lets an admin remove a plain member" do
      sign_in admin
      m = group.memberships.find_by(user: member)
      expect { delete group_membership_path(group, m) }.to change(Membership, :count).by(-1)
    end

    it "forbids an admin from removing the owner" do
      sign_in admin
      owner_m = group.memberships.find_by(user: owner)
      delete group_membership_path(group, owner_m)
      expect(Membership.exists?(owner_m.id)).to be true
    end
  end
end
