require "rails_helper"

RSpec.describe "A study that works through a list", type: :request do
  let!(:kjv)   { create(:translation, :kjv) }
  let(:owner)  { create(:user) }
  let(:member) { create(:user) }

  def book!(code, en, es, position)
    create(:book, translation: kjv, osis_code: code, name_en: en, name_es: es, position: position, testament: :new)
  end

  def verse!(book, chapter_number, number, text, red: true)
    chapter = Chapter.find_or_create_by!(book: book, number: chapter_number)
    create(:verse, chapter: chapter, number: number, body_text: text, body_html: text,
                   red_letter_ranges: red ? [ [ 0, text.length ] ] : [],
                   osis_ref: "Bible.KJV.#{book.osis_code}.#{chapter_number}.#{number}")
  end

  before do
    matthew = book!("Matt", "Matthew", "Mateo", 40)
    mark    = book!("Mark", "Mark", "Marcos", 41)
    # Lamp on a Stand (Matt.5.14-16) is the first parable; the Wise and
    # Foolish Builders (Matt.7.24-27) the second; the Sower Matt.13.3-9.
    (13..17).each { |n| verse!(matthew, 5, n, "Matthew five verse #{n}.") }
    (24..27).each { |n| verse!(matthew, 7, n, "Builders verse #{n}.") }
    verse!(matthew, 13, 2, "And great multitudes were gathered together unto him.", red: false)
    (3..9).each { |n| verse!(matthew, 13, n, "Matthew sower verse #{n}.") }
    (3..9).each { |n| verse!(mark, 4, n, "Mark sower verse #{n}.") }
    sign_in owner
  end

  describe "starting one" do
    it "offers the lists and themes on the new-study form" do
      get "/studies/new"

      options = Nokogiri::HTML(response.body).css("select[name='group[reading_list]'] option").map { |o| o[:value] }
      expect(options).to include("", "parables", "encounters", "sayings", "theme:forgiveness")
    end

    it "saves the list and makes it a red study" do
      post "/studies", params: { group: { name: "Parables", privacy: "invite_only", reading_list: "parables" } }

      group = Group.find_by!(name: "Parables")
      expect(group.reading_list).to eq("parables")
      expect(group).to be_focus_red
    end

    it "re-renders the form for a list that does not exist" do
      post "/studies", params: { group: { name: "Nope", privacy: "invite_only", reading_list: "miracles" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Group.find_by(name: "Nope")).to be_nil
    end
  end

  describe "the study page" do
    let(:group) { create(:group, owner: owner, reading_list: "parables") }

    it "lists the passages in order and marks where the study is" do
      group.update!(current_passage: "sower")

      get "/studies/#{group.id}"

      page = Nokogiri::HTML(response.body)
      items = page.css(".study-reading-list li")
      expect(items.first.at_css("a")[:href]).to eq("/studies/#{group.id}/passages/lamp-on-a-stand")
      expect(items.size).to eq(group.passages.size)
      here = page.at_css(".study-reading-list li[aria-current='step']")
      expect(here.text).to include("The Sower", I18n.t("groups.reading_list.we_are_here"))
      expect(response.body).to include(I18n.t("red.parables.title"))
    end

    it "opens at the current passage" do
      get "/studies/#{group.id}"

      expect(response.body).to include(%(href="/studies/#{group.id}/passages/lamp-on-a-stand"))
      expect(response.body).not_to include("/studies/#{group.id}/bible/kjv/matt/3")
    end

    it "is unchanged for a study with no list" do
      plain = create(:group, owner: owner)

      get "/studies/#{plain.id}"

      expect(Nokogiri::HTML(response.body).at_css(".study-reading-list")).to be_nil
    end
  end

  describe "reading a passage" do
    let(:group) { create(:group, owner: owner, reading_list: "parables") }

    it "shows only the passage's verses under the lens, in the study's reader" do
      get "/studies/#{group.id}/passages/sower"

      expect(response).to have_http_status(:ok)
      page = Nokogiri::HTML(response.body)
      expect(page.at_css("h1").text).to include("The Sower")
      expect(page.css(".chapter-body .verse").map { |v| v["data-osis-ref"] })
        .to eq((3..9).map { |n| "Bible.KJV.Matt.13.#{n}" })
      expect(page.at_css("article")[:class].split).to include("red-lens")
      expect(page.at_css("article")["data-controller"]).to include("highlight")
      expect(response.body).to include("Matthew 13:3–9")
    end

    it "steps through the study's list, not through chapters" do
      get "/studies/#{group.id}/passages/wise-and-foolish-builders"

      hrefs = Nokogiri::HTML(response.body).css("nav.study-passage-nav a").map { |a| a[:href] }
      expect(hrefs).to eq([ "/studies/#{group.id}/passages/lamp-on-a-stand",
                            "/studies/#{group.id}/passages/new-cloth-on-an-old-garment" ])
    end

    it "offers the other gospels that tell it" do
      get "/studies/#{group.id}/passages/sower"
      expect(response.body).to include(%(href="/studies/#{group.id}/passages/sower?in=mark"))

      get "/studies/#{group.id}/passages/sower", params: { in: "mark" }
      expect(response.body).to include("Mark sower verse 3.")
    end

    it "404s for a passage that is not on the study's list" do
      get "/studies/#{group.id}/passages/zacchaeus"

      expect(response).to have_http_status(:not_found)
    end

    it "404s for someone who is not in the study" do
      sign_in create(:user)

      get "/studies/#{group.id}/passages/sower"

      expect(response).to have_http_status(:not_found)
    end

    it "404s in a study that has no list" do
      plain = create(:group, owner: owner)

      get "/studies/#{plain.id}/passages/sower"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "marking where the study is" do
    let(:group) { create(:group, owner: owner, reading_list: "parables") }

    it "lets a manager move the study to a passage" do
      get "/studies/#{group.id}/passages/sower"
      expect(response.body).to include(I18n.t("groups.reading_list.mark_here"))

      patch "/studies/#{group.id}/current_passage", params: { slug: "sower" }

      expect(response).to redirect_to("/studies/#{group.id}/passages/sower")
      expect(group.reload.current_passage).to eq("sower")
    end

    it "says so instead of offering the button on the current passage" do
      group.update!(current_passage: "sower")

      get "/studies/#{group.id}/passages/sower"

      expect(response.body).to include(I18n.t("groups.reading_list.we_are_here"))
      expect(response.body).not_to include(I18n.t("groups.reading_list.mark_here"))
    end

    it "does not let a plain member move it" do
      create(:membership, user: member, group: group, role: :member)
      sign_in member

      get "/studies/#{group.id}/passages/sower"
      expect(response.body).not_to include(I18n.t("groups.reading_list.mark_here"))

      patch "/studies/#{group.id}/current_passage", params: { slug: "sower" }
      expect(response).to have_http_status(:not_found)
      expect(group.reload.current_passage).to be_nil
    end

    it "ignores a passage that is not on the list" do
      patch "/studies/#{group.id}/current_passage", params: { slug: "zacchaeus" }

      expect(response).to have_http_status(:not_found)
      expect(group.reload.current_passage).to be_nil
    end
  end
end
