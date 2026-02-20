class SearchController < ApplicationController
  MODES = %w[keyword semantic].freeze

  def index
    @query = params[:q].to_s
    @scope = params[:scope].to_s.presence || "all"
    @mode  = MODES.include?(params[:mode]) ? params[:mode] : "keyword"

    @results = @mode == "semantic" ? semantic_results : keyword_results
  end

  private

  def keyword_results
    SearchService.new(query: @query, user: current_user, scope: @scope).call
  end

  def semantic_results
    semantic = SemanticSearchService.new(query: @query, user: current_user).call
    return keyword_results.merge(semantic_fallback: true) unless semantic[:available]

    {
      verses: @scope.in?(%w[all verses]) ? semantic[:verses] : [],
      notes: [],
      semantic: true,
      notes_scope_requested: @scope == "notes"
    }
  end
end
