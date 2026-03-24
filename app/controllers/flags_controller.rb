class FlagsController < ApplicationController
  before_action :authenticate_user!

  ALLOWED_TYPES = %w[Note Comment].freeze

  def create
    type = params.dig(:flag, :flaggable_type)
    return head :unprocessable_content unless ALLOWED_TYPES.include?(type)

    target = find_target(type, params.dig(:flag, :flaggable_id))
    return head :not_found unless target

    attrs = params.require(:flag).permit(:reason, :details)
    return head :unprocessable_content unless Flag::REASONS.include?(attrs[:reason].to_s)

    # Idempotent: if the user already flagged this content, treat the
    # request as a no-op rather than surfacing an error.
    existing = Flag.find_by(user: current_user, flaggable: target)
    if existing
      render json: { flagged: true }, status: :ok and return
    end

    Flag.create!(user: current_user, flaggable: target, **attrs.to_h.symbolize_keys)
    render json: { flagged: true }, status: :created
  end

  private

  def find_target(type, id)
    case type
    when "Note"    then Note.visible_to(current_user).find_by(id: id)
    when "Comment" then Comment.visible_to(current_user).find_by(id: id)
    end
  end
end
