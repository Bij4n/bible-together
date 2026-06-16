require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let!(:user) { create(:user, username: "ruth", display_name: "Ruth") }

  it "renders the profile at the /@username handle" do
    get "/@ruth"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruth")
  end

  it "renders the profile via author_path using the username slug" do
    get author_path(user)
    expect(response).to have_http_status(:ok)
  end

  it "still resolves a profile by numeric id" do
    legacy = create(:user, username: nil, display_name: "Legacy")
    get "/authors/#{legacy.id}"
    expect(response).to have_http_status(:ok)
  end

  it "404s an unknown handle" do
    get "/@nobody"
    expect(response).to have_http_status(:not_found)
  end

  it "shows public notes with a view-and-comment link" do
    note = create(:note, :public_note, user: user)
    get author_path(user)
    expect(response.body).to include(note_path(note))
    expect(response.body).to include(I18n.t("authors.view_and_comment", count: 0))
  end
end
