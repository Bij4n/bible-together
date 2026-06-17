require "rails_helper"

RSpec.describe "Authors profile", type: :request do
  let(:author) { create(:user, username: "ruth", display_name: "Ruth", bio: "Reader and writer.") }
  let!(:public_note) { create(:note, user: author, visibility: :public_note, body: "<p>Public thought</p>") }
  let!(:private_note) { create(:note, user: author, visibility: :private_note, body: "<p>Private thought</p>") }

  it "shows only the public note count to visitors" do
    get profile_path(username: "ruth")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruth")
    expect(response.body).to include("@ruth")
    expect(response.body).to include(I18n.t("authors.stats.public"))
    expect(response.body).to include(">1<").or include(">1</dd>")
    expect(response.body).not_to include(I18n.t("authors.stats.private"))
  end

  it "shows private and public counts to the owner" do
    sign_in author
    get profile_path(username: "ruth")

    expect(response.body).to include(I18n.t("authors.stats.private"))
    expect(response.body).to include(I18n.t("authors.stats.public"))
  end

  it "counts every non-public note as private for the owner" do
    # A note posted to a study group is still private — not public.
    create(:note, user: author, visibility: :shared_groups, body: "<p>Shared with a study</p>")
    sign_in author
    get profile_path(username: "ruth")

    # 3 notes total: 1 public, 1 only-me, 1 shared-with-study.
    expect(response.body).to include("2 private")
    expect(response.body).to include("1 public")
  end
end
