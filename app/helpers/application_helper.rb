module ApplicationHelper
  # True when the current request is on the given path. Used by the
  # header and footer nav to mark the link pointing at the current
  # route in mint accent — the "you are here" cue.
  #
  # `check_parameters: false` ignores query strings, so a route like
  # /search?q=love still matches /search. Hash fragments like /#about
  # are ignored by Rails' current_page? regardless, which is why this
  # helper deliberately is NOT used on the footer About link — that
  # link points at /#about, which would erroneously match `/` and mark
  # About active on the homepage. About stays unstyled-active.
  def nav_active?(path)
    current_page?(path, check_parameters: false)
  end
end
