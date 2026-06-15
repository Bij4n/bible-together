require "rails_helper"

RSpec.describe "Theme toggle", type: :system, js: true do
  # Marketing routes (home, how-it-works, about) are forced to light per
  # DESIGN.md, so the toggle is exercised on a content surface (/search).
  it "flips data-theme on click and persists the choice across reloads" do
    visit "/search"

    # Deterministic starting point — prefers-color-scheme varies between
    # headless browser versions, and we want to assert the toggle itself.
    page.execute_script(
      "localStorage.setItem('bible-together:theme', 'light');" \
      "document.documentElement.dataset.theme = 'light';"
    )
    expect(page).to have_css(%(html[data-theme="light"]))

    # Theme toggle moved into the Account-menu dropdown in the Sprint
    # 12 navbar rewrite; open the menu before clicking it.
    open_account_menu
    find("button[data-action='theme#toggle']").click

    expect(page).to have_css(%(html[data-theme="dark"]))
    stored = page.evaluate_script("localStorage.getItem('bible-together:theme')")
    expect(stored).to eq("dark")

    visit "/search"
    expect(page).to have_css(%(html[data-theme="dark"]))
  end

  it "cycles light → dark → system → light on successive clicks" do
    visit "/search"
    page.execute_script(
      "localStorage.setItem('bible-together:theme', 'light');" \
      "document.documentElement.dataset.theme = 'light';"
    )

    open_account_menu
    button = find("button[data-action='theme#toggle']")

    button.click
    expect(page.evaluate_script("localStorage.getItem('bible-together:theme')")).to eq("dark")

    button.click
    expect(page.evaluate_script("localStorage.getItem('bible-together:theme')")).to eq("system")

    button.click
    expect(page.evaluate_script("localStorage.getItem('bible-together:theme')")).to eq("light")
    expect(page).to have_css(%(html[data-theme="light"]))
  end
end
