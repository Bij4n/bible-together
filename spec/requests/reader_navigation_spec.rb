require "rails_helper"

RSpec.describe "Reader navigation", type: :request do
  let!(:translation) { create(:translation, :kjv) }
  let!(:genesis) { create(:book, :genesis, translation: translation) }
  let!(:john)    { create(:book, :john, translation: translation) }
  let!(:gen_ch)  { create(:chapter, book: genesis, number: 1) }
  let!(:john_ch) { create(:chapter, book: john, number: 1) }
  let!(:gen_v)   { create(:verse, chapter: gen_ch, number: 1, osis_ref: "Bible.KJV.Gen.1.1") }
  let!(:john_v)  { create(:verse, chapter: john_ch, number: 1, osis_ref: "Bible.KJV.John.1.1") }

  describe "book picker on the community reader (guest)" do
    before { get "/bible/kjv/gen/1" }

    it "renders successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "groups books by Old and New Testament" do
      expect(response.body).to include(I18n.t("bible.reader.old_testament"))
      expect(response.body).to include(I18n.t("bible.reader.new_testament"))
    end

    it "links each book to its first chapter, preserving the community layer" do
      expect(response.body).to include("/bible/kjv/gen/1?layer=community")
      expect(response.body).to include("/bible/kjv/john/1?layer=community")
    end

    it "labels the book picker for assistive tech" do
      expect(response.body).to include(I18n.t("bible.reader.book_picker"))
    end
  end
end
