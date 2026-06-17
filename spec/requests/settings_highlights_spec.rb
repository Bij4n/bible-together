require "rails_helper"

RSpec.describe "Settings highlight preferences", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "saves toolbar colors, labels, and default note marker" do
    patch settings_path, params: {
      user: {
        highlight_toolbar_colors: %w[yellow green blue],
        highlight_color_labels: { "yellow" => "Prayer", "green" => "Study" },
        default_note_color: "amber"
      }
    }, headers: { "Turbo-Frame" => "settings_highlights" }

    expect(response).to have_http_status(:ok)
    user.reload
    expect(user.toolbar_colors).to eq(%w[yellow green blue])
    expect(user.highlight_label_for("yellow")).to eq("Prayer")
    expect(user.default_note_color).to eq("amber")
  end

  it "rejects saving with no toolbar colors selected" do
    patch settings_path, params: {
      user: { highlight_toolbar_colors: [ "" ] }
    }, headers: { "Turbo-Frame" => "settings_highlights" }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
