FactoryBot.define do
  factory :flag do
    association :user
    flaggable { association(:note) }
    reason { "inappropriate" }
    details { "Test details." }
  end
end
