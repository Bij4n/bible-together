require "rails_helper"

RSpec.describe "Layout chrome", type: :request do
  it "applies responsive page gutters so content never hugs the viewport edge" do
    get "/"
    expect(response.body).to include("px-6 sm:px-8 lg:px-12")
  end

  it "uses the wide marketing container with gutters on marketing pages" do
    get "/"
    expect(response.body).to include("max-w-6xl px-6 sm:px-8 lg:px-12")
  end

  it "scales the main vertical rhythm responsively so every page sits at a consistent offset" do
    get "/"
    expect(response.body).to include("py-10 sm:py-12 lg:py-16")
  end
end
