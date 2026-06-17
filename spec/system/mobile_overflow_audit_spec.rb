require "rails_helper"

# Platform-wide mobile-width audit. Renders each primary surface at a
# 375px viewport and asserts nothing overflows horizontally (the user
# should never have to side-scroll). The homepage has its own dedicated
# audit in home_mobile_audit_spec; this covers the rest of the platform
# so a future change can't silently reintroduce side-scroll anywhere.
# Structural contract only — human review still owns the aesthetic feel.
RSpec.describe "Mobile overflow audit", type: :system, js: true do
  let!(:translation) { create(:translation, :kjv) }
  let!(:book)        { create(:book, :genesis, translation: translation) }
  let!(:chapter)     { create(:chapter, book: book, number: 1) }
  let!(:verse) do
    create(:verse, chapter: chapter, number: 1,
                   body_text: "In the beginning God created the heaven and the earth.",
                   body_html: "In the beginning God created the heaven and the earth.",
                   red_letter_ranges: [],
                   osis_ref: "Bible.KJV.Gen.1.1")
  end
  let!(:author) { create(:user, username: "mark") }
  let!(:thread) do
    create(:forum_thread, user: author,
                          title: "A deliberately long forum thread title that should wrap instead of forcing the page to scroll sideways")
  end
  let!(:forum_post) { create(:forum_post, forum_thread: thread, user: author, body: "A forum reply.") }

  before do
    BitcoinAddress.rotate_to!(address: "bc1qfzfen6peqgqmc03gj2jsu0zc96s49dwgahvu2l")
    @original_window_size = page.driver.browser.manage.window.size
    page.driver.browser.manage.window.resize_to(375, 800)
  end

  after do
    page.driver.browser.manage.window.resize_to(@original_window_size.width, @original_window_size.height)
  end

  def expect_no_horizontal_overflow
    document_width = page.evaluate_script("document.documentElement.scrollWidth")
    viewport_width = page.evaluate_script("document.documentElement.clientWidth")
    expect(document_width).to be <= viewport_width + 1
  end

  context "public surfaces" do
    before do
      @paths = {
        "about"        => "/about",
        "how it works" => "/how-it-works",
        "contact"      => "/contact",
        "donate"       => "/donate",
        "search"       => "/search",
        "forum index"  => "/forum",
        "forum thread" => "/forum/#{thread.id}",
        "public notes" => "/community",
        "reader"       => "/bible/kjv/gen/1"
      }
    end

    it "does not overflow on any public surface at 375px" do
      aggregate_failures do
        @paths.each do |name, path|
          visit path
          document_width = page.evaluate_script("document.documentElement.scrollWidth")
          viewport_width = page.evaluate_script("document.documentElement.clientWidth")
          expect(document_width).to(be <= viewport_width + 1, "#{name} (#{path}) overflows: #{document_width}px > #{viewport_width}px")
        end
      end
    end
  end

  context "signed-in surfaces" do
    let!(:user) { create(:user, username: "ruth") }

    before { sign_in user }

    it "does not overflow on any signed-in surface at 375px" do
      paths = {
        "dashboard"  => "/",
        "settings"   => "/settings",
        "my studies" => "/studies",
        "my notes"   => "/notes",
        "profile"    => "/@ruth"
      }

      aggregate_failures do
        paths.each do |name, path|
          visit path
          document_width = page.evaluate_script("document.documentElement.scrollWidth")
          viewport_width = page.evaluate_script("document.documentElement.clientWidth")
          expect(document_width).to(be <= viewport_width + 1, "#{name} (#{path}) overflows: #{document_width}px > #{viewport_width}px")
        end
      end
    end
  end
end
