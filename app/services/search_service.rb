class SearchService
  VALID_SCOPES = %w[all verses notes].freeze
  VERSE_LIMIT  = 20
  NOTE_LIMIT   = 20

  attr_reader :query, :user, :scope

  def initialize(query:, user: nil, scope: "all")
    @query = query.to_s.strip
    @user  = user
    @scope = scope.to_s
  end

  def call
    return empty_result if query.empty?
    return empty_result unless VALID_SCOPES.include?(scope)

    {
      verses: scope_verses ? search_verses : [],
      notes:  scope_notes  ? search_notes  : []
    }
  end

  private

  def scope_verses
    scope == "all" || scope == "verses"
  end

  def scope_notes
    scope == "all" || scope == "notes"
  end

  def search_verses
    # with_pg_search_highlight is added to the relation pg_search
    # returns — chain it *after* search_text, not before.
    Verse
      .search_text(query)
      .with_pg_search_highlight
      .includes(chapter: { book: :translation })
      .limit(VERSE_LIMIT)
      .to_a
  end

  def search_notes
    # The :joins pg_search generates for associated_against plays
    # poorly with our custom Note.visible_to SQL if we chain search_body
    # on top — combine by pluck + where id in instead. Anonymous
    # visitors see only public notes; signed-in users see everything
    # they have visibility into.
    visible = user ? Note.visible_to(user) : Note.public_visible
    matching_ids = Note.search_body(query).limit(NOTE_LIMIT * 3).ids
    visible.where(id: matching_ids)
           .includes(:user, :highlights)
           .limit(NOTE_LIMIT)
           .to_a
  end

  def empty_result
    { verses: [], notes: [] }
  end
end
