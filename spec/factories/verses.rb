FactoryBot.define do
  factory :verse do
    association :chapter
    sequence(:number) { |n| n }
    body_text { "In the beginning God created the heaven and the earth." }
    body_html { "In the beginning God created the heaven and the earth." }
    red_letter_ranges { [] }
    # Mirrors what the importer stores: his words on their own.
    red_text { Verse.red_text_for(body_text, red_letter_ranges) }
    sequence(:osis_ref) { |n| "Bible.KJV.Gen.1.#{n}" }
  end
end
