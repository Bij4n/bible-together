FactoryBot.define do
  factory :forum_post do
    association :forum_thread
    association :user
    body { "A forum reply." }
  end
end
