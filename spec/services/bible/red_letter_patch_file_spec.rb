require "rails_helper"

# The real translations aren't loaded in the test database, so this
# checks the shape of the checked-in patch files. Whether every passage
# is actually in its verse is enforced when the patch is applied.
RSpec.describe "config/red_letter patch files" do
  Rails.root.glob("config/red_letter/*.yml").each do |path|
    describe path.basename.to_s do
      let(:entries) { YAML.safe_load_file(path) }

      it "keys every entry by a canonical Book.chapter.verse" do
        books = Bible::CanonicalBooks.osis_codes

        entries.each_key do |ref|
          book, chapter, verse = ref.split(".")
          expect(books).to include(book), "#{ref}: unknown book"
          expect([ chapter, verse ]).to all(match(/\A[1-9]\d*\z/)), "#{ref}: bad chapter or verse"
        end
      end

      it "lists at least one non-blank passage per verse" do
        entries.each do |ref, passages|
          expect(passages).to be_an(Array).and(be_present), "#{ref}: no passages"
          expect(passages).to all(be_a(String).and(match(/\S/))), "#{ref}: blank passage"
        end
      end

      it "has no passage with stray leading or trailing whitespace" do
        entries.each do |ref, passages|
          expect(passages).to all(satisfy { |p| p == p.strip }), "#{ref}: untrimmed passage"
        end
      end
    end
  end
end
