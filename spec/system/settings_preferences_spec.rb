require "rails_helper"

RSpec.describe "Settings preferences", type: :system, js: true do
  let(:user) { create(:user, email: "reader@bible-together.test", ui_locale: "en") }

  before { sign_in user }

  it "persists a signed-in user's language choice across reloads" do
    visit "/settings"
    choose "Español"

    expect(page).to have_content(/preferences saved|preferencias guardadas/i)
    expect(user.reload.ui_locale).to eq("es")

    visit "/"
    expect(page).to have_content(I18n.t("home.dashboard.heading", locale: :es))
    expect(page).to have_css("html[lang='es']")
  end

  it "persists signed-out language switching via session" do
    sign_out user
    visit "/"
    expect(page).to have_content(I18n.t("home.welcome", locale: :en))

    # Language toggle is in the footer — no menu to open.
    within("footer") { click_on "ES" }
    expect(page).to have_content(I18n.t("home.welcome", locale: :es))

    # Navigate elsewhere without carrying a locale param — session should
    # still apply.
    visit "/users/sign_in"
    expect(page).to have_css("html[lang='es']")
  end
end
