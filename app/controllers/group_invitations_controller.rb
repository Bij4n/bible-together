class GroupInvitationsController < ApplicationController
  # Sprint 23.3 — full controller for email-based group invitations.
  #
  # - #create: owner sends an invitation. Authenticated + owner-gated.
  # - #destroy: owner cancels a pending invitation. Same gates.
  # - #show: recipient clicks the email link.
  #     - If signed in → accept!, redirect to the group's bible reader.
  #     - If signed out → stash the token in a signed cookie
  #       (cookies.signed[:pending_group_invitation_token], 1-hour
  #       TTL) and redirect to /users/sign_in. We use a cookie rather
  #       than the Rails session because warden rotates the session
  #       on sign-in/sign-up, wiping plain session keys. The cookie
  #       survives the rotation. ApplicationController#after_sign_
  #       in_path_for picks it back up post-auth (works for both
  #       sign-in and sign-up paths since Devise's
  #       after_sign_up_path_for defaults to after_sign_in_path_for)
  #       and redirects back here, where the signed-in branch
  #       consumes the cookie + accepts.
  before_action :authenticate_user!, only: %i[create destroy]

  def create
    @group = Group.find_by(id: params[:group_id])
    return head :not_found unless @group&.manager?(current_user)

    invitation = @group.group_invitations.build(
      email: invitation_params[:email],
      invited_by: current_user
    )

    if already_member?(@group, invitation.email)
      redirect_to(group_path(@group),
                  alert: t("group_invitations.create.already_member", email: invitation.email))
      return
    end

    if invitation.save
      GroupInvitationMailer.invite(invitation).deliver_later
      redirect_to(group_path(@group),
                  notice: t("group_invitations.create.sent", email: invitation.email))
    else
      redirect_to(group_path(@group),
                  alert: invitation.errors.full_messages.to_sentence)
    end
  end

  def destroy
    invitation = GroupInvitation.find_by(id: params[:id], group_id: params[:group_id])
    return head :not_found unless invitation
    return head :not_found unless invitation.group.manager?(current_user)

    invitation.destroy!
    redirect_to(group_path(invitation.group),
                notice: t("group_invitations.destroy.cancelled", email: invitation.email))
  end

  def show
    invitation = GroupInvitation.find_by(token: params[:token])

    if invitation.nil? || invitation.expired?
      render :expired, status: :gone
      return
    end

    if invitation.accepted?
      redirect_to_group_or_sign_in(invitation)
      return
    end

    unless user_signed_in?
      # Stash the token in a controlled session key (not Devise's
      # stored_location, which has different consume semantics across
      # sign-in vs sign-up flows). ApplicationController's
      # after_sign_in_path_for override picks it up + redirects back
      # here after auth, where the signed-in branch fires accept!.
      cookies.signed[:pending_group_invitation_token] = { value: invitation.token, expires: 1.hour.from_now }
      flash[:notice] = t("group_invitations.show.sign_in_to_accept")
      redirect_to new_user_session_path
      return
    end

    cookies.delete(:pending_group_invitation_token)
    invitation.accept!(current_user)
    redirect_to(
      group_bible_chapter_path(invitation.group, translation: "kjv", book: "gen", chapter: 1),
      notice: t("group_invitations.show.joined", group_name: invitation.group.name)
    )
  end

  private

  def invitation_params
    params.require(:group_invitation).permit(:email)
  end

  def already_member?(group, email)
    return false if email.blank?

    User.where("LOWER(email) = ?", email.to_s.downcase).any? do |u|
      group.member?(u)
    end
  end

  def redirect_to_group_or_sign_in(invitation)
    if user_signed_in?
      redirect_to(
        group_bible_chapter_path(invitation.group, translation: "kjv", book: "gen", chapter: 1),
        notice: t("group_invitations.show.already_accepted")
      )
    else
      cookies.signed[:pending_group_invitation_token] = { value: invitation.token, expires: 1.hour.from_now }
      redirect_to new_user_session_path,
                  notice: t("group_invitations.show.sign_in_to_accept")
    end
  end
end
