module NavbarHelpers
  # Opens the Account menu dropdown. The menu is a Stimulus controller
  # (user_menu_controller.js); the trigger is keyed via
  # data-user-menu-target='trigger'. If this helper breaks, check the
  # controller's target names first — the attribute is the contract,
  # not the aria-label (which is locale-dependent).
  def open_account_menu
    find("button[data-user-menu-target='trigger']").click
  end
end

RSpec.configure do |config|
  config.include NavbarHelpers, type: :system
end
