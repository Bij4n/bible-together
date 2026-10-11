require "rails_helper"

RSpec.describe "Studying Highlighted in Red instead of the whole Bible", type: :request do
  let!(:kjv) { create(:translation, :kjv) }
  let(:genesis) { create(:book, translation: kjv, osis_code: "Gen", name_en: "Genesis", name_es: "Génesis", position: 1, testament: :old) }
  let(:matthew) { create(:book, translation: kjv, osis_code: "Matt", name_en: "Matthew", name_es: "Mateo", position: 40, testament: :new) }
  let(:john)    { create(:book, translation: kjv, osis_code: "John", name_en: "John", name_es: "Juan", position: 43, testament: :new) }

  def verse!(book, chapter_number, number, text, red: nil)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ red ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    verse!(genesis, 1, 1, "In the beginning God created the heaven and the earth.")
    verse!(matthew, 4, 18, "And Jesus, walking by the sea of Galilee, saw two brethren.")
    verse!(matthew, 4, 19, "And he saith unto them, Follow me.", red: [ 24, 34 ])
    verse!(matthew, 5, 1, "And seeing the multitudes, he went up into a mountain.")
    verse!(john, 3, 16, "For God so loved the world.", red: [ 0, 27 ])
  end

  describe "a reader's own focus" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "is the whole Bible unless they choose otherwise" do
      expect(user).to be_focus_bible

      get "/bible"
      expect(response).to redirect_to("/bible/kjv/gen/1")
    end

    it "is chosen in settings" do
      get "/settings"
      expect(response.body).to include(I18n.t("settings.sections.study_focus.title"))

      patch "/settings", params: { user: { study_focus: "red" } }
      expect(user.reload).to be_focus_red
    end

    it "rejects a focus that does not exist" do
      patch "/settings", params: { user: { study_focus: "everything" } }

      expect(user.reload).to be_focus_bible
    end

    context "once it is Highlighted in Red" do
      before { user.update!(study_focus: :red) }

      it "sends /bible to the red reader" do
        get "/bible"

        expect(response).to redirect_to("/red/words")
      end

      it "points Read and the dashboard at the first red chapter" do
        get "/"

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("header.site-header nav.site-nav a.site-nav-link")[:href]).to eq("/red/kjv/matt/4")
        expect(page.at_css("[aria-labelledby='continue-reading-heading'] a")[:href]).to eq("/red/kjv/matt/4")
        expect(response.body).to include("Matthew 4")
      end

      it "continues from their last highlight, under the lens when that chapter has red text" do
        create(:highlight, user: user, translation: kjv, osis_ref: "Bible.KJV.John.3.16")

        get "/"

        expect(Nokogiri::HTML(response.body).at_css("[aria-labelledby='continue-reading-heading'] a")[:href])
          .to eq("/red/kjv/john/3")
      end

      it "continues in the ordinary reader when their last highlight is somewhere with no red text" do
        create(:highlight, user: user, translation: kjv, osis_ref: "Bible.KJV.Gen.1.1")

        get "/"

        expect(Nokogiri::HTML(response.body).at_css("[aria-labelledby='continue-reading-heading'] a")[:href])
          .to eq("/bible/kjv/gen/1")
      end
    end
  end

  describe "a study's focus" do
    let(:owner) { create(:user) }

    before { sign_in owner }

    it "is offered when starting a study and saved" do
      get "/studies/new"
      expect(response.body).to include(I18n.t("groups.focus.red"))

      post "/studies", params: { group: { name: "Red letters", privacy: "invite_only", focus: "red" } }
      expect(Group.find_by!(name: "Red letters")).to be_focus_red
    end

    it "defaults to the whole Bible" do
      post "/studies", params: { group: { name: "Genesis", privacy: "invite_only" } }

      expect(Group.find_by!(name: "Genesis")).to be_focus_bible
    end

    context "for a study of Highlighted in Red" do
      let(:group) { create(:group, owner: owner, focus: :red) }

      it "opens at the first chapter with red text" do
        get "/studies/#{group.id}"

        expect(response.body).to include(%(href="/studies/#{group.id}/bible/kjv/matt/4"))
        expect(response.body).to include(I18n.t("groups.focus.red"))
      end

      it "reads under the red lens and steps only through red chapters" do
        get "/studies/#{group.id}/bible/kjv/matt/4"

        expect(response).to have_http_status(:ok)
        page = Nokogiri::HTML(response.body)
        expect(page.at_css("article")[:class].split).to include("red-lens")
        expect(page.at_css(".chapter-body")[:class]).to include("text-surface-500")
        expect(response.body).to include(I18n.t("bible.reader.red.words_only"))
        expect(page.css("nav.study-chapter-nav a").map { |a| a[:href] })
          .to eq([ "/studies/#{group.id}/bible/kjv/john/3" ])
      end
    end

    it "leaves an ordinary study's reader as it was" do
      group = create(:group, owner: owner)

      get "/studies/#{group.id}/bible/kjv/matt/4"

      page = Nokogiri::HTML(response.body)
      expect(page.at_css("article")[:class].split).not_to include("red-lens")
      expect(page.at_css("nav.study-chapter-nav")).to be_nil
      expect(response.body).not_to include(I18n.t("bible.reader.red.words_only"))
    end
  end
end
