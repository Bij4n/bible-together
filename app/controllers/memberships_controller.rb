class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_group
  before_action :ensure_group_owner

  def destroy
    membership = @group.memberships.find(params[:id])
    membership.destroy!
    redirect_to group_path(@group), notice: t("memberships.removed"), status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to group_path(@group), alert: t("memberships.cannot_remove_last_owner")
  end

  private

  def load_group
    @group = Group.find(params[:group_id])
  end

  def ensure_group_owner
    head :not_found unless @group.owner_id == current_user.id
  end
end
