require "rails_helper"

RSpec.describe "Sitemap", type: :request do
  let!(:translation) { create(:translation, :kjv) }
  let!(:book)        { create(:book, :john, translation: translation) }
  let!(:chapter)     { create(:chapter, book: book, number: 3) }

  it "renders /sitemap.xml as XML with the static + bible chapter URLs" do
    get "/sitemap.xml"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
    expect(response.body).to start_with("<?xml")
    expect(response.body).to include("<urlset")
    expect(response.body).to include(root_url)
    expect(response.body).to include(about_url)
    expect(response.body).to include(donate_url)
    expect(response.body).to include(search_url)
    expect(response.body).to include(bible_chapter_url(translation: "kjv", book: "john", chapter: 3))
  end

  it "lists Highlighted in Red: its front page, lists, passages, themes and red chapters" do
    create(:verse, chapter: chapter, number: 16, body_text: "For God so loved the world.",
                   body_html: "For God so loved the world.", red_letter_ranges: [ [ 0, 27 ] ],
                   osis_ref: "Bible.KJV.John.3.16")
    create(:chapter, book: book, number: 4)

    get "/sitemap.xml"

    expect(response.body).to include("<loc>#{red_home_url}</loc>")
    %w[parables encounters sayings].each do |collection|
      expect(response.body).to include("<loc>#{red_passages_url(collection: collection)}</loc>")
    end
    expect(response.body).to include("<loc>#{red_themes_url}</loc>")
    expect(response.body).to include("<loc>#{red_passage_url(collection: 'parables', slug: 'prodigal-son')}</loc>")
    expect(response.body).to include("<loc>#{red_passage_url(collection: 'encounters', slug: 'zacchaeus')}</loc>")
    expect(response.body).to include("<loc>#{red_theme_url('forgiveness')}</loc>")
    expect(response.body).to include("<loc>#{red_chapter_url(translation: 'kjv', book: 'john', chapter: 3)}</loc>")
    expect(response.body).not_to include(red_chapter_url(translation: "kjv", book: "john", chapter: 4))
  end

  it "is reachable without authentication" do
    get "/sitemap.xml"
    expect(response).to have_http_status(:ok)
  end
end
