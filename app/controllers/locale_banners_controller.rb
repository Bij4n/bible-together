class LocaleBannersController < ApplicationController
  # Persistent per-browser dismissal. A signed cookie lets us detect
  # dismissal without a user-preference column; good-enough stickiness
  # for a nudge banner without a schema change. Falls back to root
  # when there's no referrer (direct POST from a test or a bookmarked
  # endpoint, neither of which we care about beyond not 404ing).
  def dismiss
    cookies.permanent.signed[:locale_banner_dismissed] = "1"
    redirect_back(fallback_location: root_path)
  end
end
