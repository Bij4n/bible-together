FactoryBot.define do
  factory :forum_thread do
    association :user
    sequence(:title) { |n| "Forum thread #{n}" }
  end
end
