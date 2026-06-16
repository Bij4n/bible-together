class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_group
  before_action :ensure_group_manager, only: [ :destroy ]
  before_action :ensure_group_owner,   only: [ :update ]

  # Owner-only: promote a member to admin or demote an admin to member.
  def update
    membership = @group.memberships.find(params[:id])
    new_role = params.require(:membership).permit(:role)[:role]

    unless %w[member admin].include?(new_role)
      redirect_to(group_path(@group), alert: t("memberships.invalid_role")) and return
    end

    membership.update!(role: new_role)
    redirect_to group_path(@group), notice: t("memberships.role_updated")
  rescue ActiveRecord::RecordInvalid
    redirect_to group_path(@group), alert: t("memberships.cannot_remove_last_owner")
  end

  def destroy
    membership = @group.memberships.find(params[:id])

    # Admins may remove plain members only; owners may remove anyone
    # (last-owner protection still applies via the model callback).
    unless @group.owner_id == current_user.id || membership.member?
      redirect_to(group_path(@group), alert: t("memberships.insufficient_role")) and return
    end

    membership.destroy!
    redirect_to group_path(@group), notice: t("memberships.removed"), status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to group_path(@group), alert: t("memberships.cannot_remove_last_owner")
  end

  private

  def load_group
    @group = Group.find(params[:group_id])
  end

  def ensure_group_manager
    head :not_found unless @group.manager?(current_user)
  end

  def ensure_group_owner
    head :not_found unless @group.owner_id == current_user.id
  end
end
