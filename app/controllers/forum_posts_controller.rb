class ForumPostsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]
  before_action :require_admin!, only: %i[hide unhide]

  def create
    thread = ForumThread.visible.find(params[:forum_thread_id])
    post = thread.forum_posts.build(user: current_user, body: params.dig(:forum_post, :body))

    if post.save
      redirect_to forum_thread_path(thread, anchor: "post_#{post.id}"), notice: t("forum.reply_posted")
    else
      redirect_to forum_thread_path(thread), alert: post.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def hide
    post = ForumPost.find(params[:id])
    post.hide!(current_user)
    redirect_to forum_thread_path(post.forum_thread), notice: t("forum.post_hidden")
  end

  def unhide
    post = ForumPost.find(params[:id])
    post.unhide!
    redirect_to forum_thread_path(post.forum_thread), notice: t("forum.post_unhidden")
  end

  private

  def require_admin!
    head :not_found unless current_user&.admin?
  end
end
