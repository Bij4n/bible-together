# Follow/unfollow an author (Sprint R5). Nested under /authors/:author_id
# as a singular resource. Self-follow and unknown ids both 404 — the
# model + DB constraints back this up, but the controller answers
# cleanly instead of bubbling a validation error.
class FollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.follow!(author)
    redirect_to author_path(author)
  end

  def destroy
    current_user.unfollow!(author)
    redirect_to author_path(author)
  end

  private

  def author
    @author ||= begin
      found = User.find(params[:author_id])
      raise ActiveRecord::RecordNotFound if found == current_user
      found
    end
  end
end
