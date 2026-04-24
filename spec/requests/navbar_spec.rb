require "rails_helper"

# Structural assertions on the navbar dropdown introduced in Sprint 12.
# Request-level coverage rather than a system spec because the
# dropdown's JS behavior (toggle, click-outside, Escape) is a thin
# Stimulus controller the user is verifying locally; what belongs in
# CI is "does the rendered markup contain the right items behind the
# user-menu trigger." We hit a cheap page (the Devise sign-in view)
# so the spec doesn't need the bible fixture tree.
RSpec.describe "Navbar", type: :request do
  describe "signed-out visitors" do
    before { get "/users/sign_in" }

    it "wires the user-menu Stimulus controller with a trigger + menu pair" do
      expect(response.body).to include('data-controller="user-menu"')
      expect(response.body).to include('data-user-menu-target="trigger"')
      expect(response.body).to include('data-user-menu-target="menu"')
    end

    it "places sign-in and sign-up inside the menu" do
      expect(response.body).to include("Sign in")
      expect(response.body).to include("Sign up")
    end

    it "places the theme toggle and both locale options inside the menu" do
      expect(response.body).to include("Toggle theme")
      expect(response.body).to include("English")
      expect(response.body).to include("Español")
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
end
