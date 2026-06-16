class ForumThreadsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create]
  before_action :require_admin!, only: %i[hide unhide]

  def index
    @threads = ForumThread.visible.recent.includes(:user).limit(100)
  end

  def show
    @thread = ForumThread.visible.find(params[:id])
    @posts  = @thread.forum_posts.visible.includes(:user).order(:created_at)
    @post   = ForumPost.new
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def new
    @thread = ForumThread.new
  end

  def create
    @thread = current_user.forum_threads.build(thread_params)
    @first_body = params.dig(:forum_thread, :body).to_s

    if @first_body.blank?
      @thread.errors.add(:base, t("forum.body_required"))
      return render :new, status: :unprocessable_content
    end

    if @thread.save
      @thread.forum_posts.create!(user: current_user, body: @first_body)
      redirect_to forum_thread_path(@thread), notice: t("forum.thread_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def hide
    ForumThread.find(params[:id]).hide!(current_user)
    redirect_to forum_threads_path, notice: t("forum.thread_hidden")
  end

  def unhide
    ForumThread.find(params[:id]).unhide!
    redirect_to forum_thread_path(params[:id]), notice: t("forum.thread_unhidden")
  end

  private

  def thread_params
    params.require(:forum_thread).permit(:title)
  end

  def require_admin!
    head :not_found unless current_user&.admin?
  end
end
