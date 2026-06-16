require "rails_helper"

RSpec.describe "Auth flows", type: :system, js: true do
  it "signs up a new user and lands them in a signed-in state" do
    visit "/users/sign_up"

    fill_in "Email", with: "scribe@bible-together.test"
    fill_in "Password", with: "correct horse battery staple"
    fill_in "Password confirmation", with: "correct horse battery staple"
    find('input[type="submit"][value*="Sign up"]').click

    expect(page).to have_content("Welcome! You have signed up successfully.")

    # Settings + Sign out moved into the Account-menu dropdown in the
    # Sprint 12 navbar rewrite.
    open_account_menu

    expect(page).to have_link(text: /settings/i)
    expect(page).to have_button(text: /sign out/i)
    expect(User.find_by(email: "scribe@bible-together.test")).to be_present
  end

  it "signs a user in and out" do
    user = create(:user, email: "reader@bible-together.test")

    visit "/users/sign_in"
    fill_in "Email", with: user.email
    fill_in "Password", with: "correct horse battery staple"
    find('input[type="submit"][value*="Sign in"]').click

    expect(page).to have_content("Signed in successfully.")

    open_account_menu
    expect(page).to have_button(text: /sign out/i)
    click_button "Sign out"

    # Signed-out desktop chrome exposes Sign in as a direct header link
    # (no account menu), where the signed-in state showed the avatar menu.
    expect(page).to have_link(text: /sign in/i)
  end
end
