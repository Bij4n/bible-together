FactoryBot.define do
  factory :chapter do
    association :book
    sequence(:number) { |n| n }
    verse_count { 0 }
  end
end
