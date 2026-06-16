require "rails_helper"

# Structural assertions on the site header + footer chrome for the
# Read / Study / Explore IA. Request-level rather than system because
# dropdown JS is covered elsewhere; CI checks the rendered markup.
RSpec.describe "Navbar", type: :request do
  describe "signed-out visitors" do
    before { get "/" }

    it "wires the user-menu Stimulus controller with a trigger + menu pair" do
      expect(response.body).to include('data-controller="user-menu"')
      expect(response.body).to include('data-user-menu-target="trigger"')
      expect(response.body).to include('data-user-menu-target="menu"')
    end

    it "renders Study and Explore menu triggers in the site header" do
      expect(response.body).to include(I18n.t("layout.open_explore_menu"))
      expect(response.body).to include(I18n.t("layout.explore_menu"))
    end

    it "shows sign-in and start reading in the header rail" do
      expect(response.body).to include("Sign in")
      expect(response.body).to include("Start reading")
      expect(response.body).not_to include("Sign up")
    end

    it "places locale options in the footer and omits a navbar theme toggle" do
      expect(response.body).to include("English")
      expect(response.body).to include("Español")
      expect(response.body).not_to include(%(aria-label="Switch theme"))
    end

    it "does not render a signed-in-only item" do
      expect(response.body).not_to include(">Sign out<")
      expect(response.body).not_to include(">Admin<")
    end
  end

  describe "signed-in regular users" do
    let(:user) { create(:user) }

    before do
      sign_in user
      get "/"
    end

    it "places settings and sign-out inside the menu" do
      expect(response.body).to include(">Settings<")
      expect(response.body).to include("Sign out")
    end

    it "hides sign-in, sign-up, and admin" do
      expect(response.body).not_to include(">Sign in<")
      expect(response.body).not_to include(">Sign up<")
      expect(response.body).not_to include(">Admin<")
    end
  end

  describe "signed-in admins" do
    let(:admin) { create(:user, admin: true) }

    before do
      sign_in admin
      get "/"
    end

    it "surfaces the admin link inside the menu" do
      expect(response.body).to include(">Admin<")
    end
  end

  describe "account-menu active state" do
    let(:user) { create(:user) }
    before { sign_in user }

    it "marks Settings active when on /settings" do
      get "/settings"
      expect(response.body).to match(/<a[^>]*bg-surface-100 text-accent-800[^>]*>Settings/)
    end

    it "does not mark Settings active on the homepage" do
      get "/"
      expect(response.body).not_to match(/<a[^>]*bg-surface-100 text-accent-800[^>]*>Settings/)
    end
  end

  describe "admin link active state" do
    let(:admin) { create(:user, admin: true) }
    before { sign_in admin }

    it "marks Admin active anywhere under /admin" do
      get "/admin/notes"
      expect(response.body).to match(/<a[^>]*bg-surface-100 text-accent-800[^>]*>Admin/)
    end

    it "marks Admin active on /admin/flags too (not just /admin/notes)" do
      get "/admin/flags"
      expect(response.body).to match(/<a[^>]*bg-surface-100 text-accent-800[^>]*>Admin/)
    end

    it "does not mark Admin active on /settings" do
      get "/settings"
      expect(response.body).not_to match(/<a[^>]*bg-surface-100 text-accent-800[^>]*>Admin/)
    end
  end
end
