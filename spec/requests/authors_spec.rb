require "rails_helper"

RSpec.describe "Authors profile", type: :request do
  let(:author) { create(:user, username: "ruth", display_name: "Ruth", bio: "Reader and writer.") }
  let!(:public_note) { create(:note, user: author, visibility: :public_note, body: "<p>Public thought</p>") }
  let!(:private_note) { create(:note, user: author, visibility: :private_note, body: "<p>Private thought</p>") }

  it "shows public note stats to visitors" do
    get profile_path(username: "ruth")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruth")
    expect(response.body).to include("@ruth")
    expect(response.body).to include(I18n.t("authors.stats.public"))
    expect(response.body).to include(">1<").or include(">1</dd>")
    expect(response.body).not_to include(I18n.t("authors.stats.private"))
  end

  it "shows full note stats to the profile owner" do
    sign_in author
    get profile_path(username: "ruth")

    expect(response.body).to include(I18n.t("authors.stats.total"))
    expect(response.body).to include(I18n.t("authors.stats.private"))
    expect(response.body).to include(I18n.t("authors.stats.public"))
  end
end
