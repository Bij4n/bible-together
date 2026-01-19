FactoryBot.define do
  factory :verse do
    association :chapter
    sequence(:number) { |n| n }
    body_text { "In the beginning God created the heaven and the earth." }
    body_html { "In the beginning God created the heaven and the earth." }
    red_letter_ranges { [] }
    sequence(:osis_ref) { |n| "Bible.KJV.Gen.1.#{n}" }
  end
end
