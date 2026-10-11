require "rails_helper"
require "rake"

RSpec.describe "bible:red_letter rake tasks" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("bible:red_letter:apply")
  end

  let!(:kjv)  { create(:translation, :kjv) }
  let!(:mini) { create(:translation, code: "RV1909_MINI", name: "RV1909 Mini", language: "es") }

  def verse_in(translation, body, ranges: [])
    book = create(:book, osis_code: "John", translation: translation,
                         name_en: "John", name_es: "Juan", position: 43, testament: :new)
    chapter = create(:chapter, book: book, number: 3)
    create(:verse, chapter: chapter, number: 14, body_text: body, body_html: body,
                   red_letter_ranges: ranges, osis_ref: "Bible.#{translation.code}.John.3.14")
  end

  describe "apply" do
    before { Rake::Task["bible:red_letter:apply"].reenable }

    it "marks the verses listed in the translation's patch file" do
      verse = verse_in(mini, "Y como Moisés levantó la serpiente en el desierto, " \
                             "así es necesario que el Hijo del hombre sea levantado;")

      expect { Rake::Task["bible:red_letter:apply"].invoke("rv1909_mini") }
        .to output(/marked 1 verses/).to_stdout

      expect(verse.reload.red_letter_ranges).not_to be_empty
    end
  end

  describe "propose" do
    before { Rake::Task["bible:red_letter:propose"].reenable }

    it "prints a draft patch for verses that are partly red in the source" do
      en = "And Jesus said unto him, This day is salvation come to this house."
      verse_in(kjv, en, ranges: [ [ 25, en.length ] ])
      verse_in(mini, "Y Jesús le dijo: Hoy ha venido la salvación á esta casa.")

      expect { Rake::Task["bible:red_letter:propose"].invoke("rv1909_mini") }
        .to output(/John\.3\.14:\n  - "Hoy ha venido la salvación á esta casa\."/).to_stdout
    end
  end
end
