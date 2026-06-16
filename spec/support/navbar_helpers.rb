module NavbarHelpers
  # Opens the desktop avatar Account menu (signed-in only). The header now
  # carries three user-menu triggers (Study, Explore, account), so target
  # the avatar by its stable class rather than the shared
  # data-user-menu-target attribute. Specs run at desktop width by default,
  # where the avatar is visible and the mobile tab bar is hidden.
  def open_account_menu
    find("button.site-nav-avatar").click
  end
end

RSpec.configure do |config|
  config.include NavbarHelpers, type: :system
end
