FactoryBot.define do
  factory :note do
    association :user
    visibility { "private_note" }
    color { "violet" }
    body { "A note." }

    trait :shared_users do
      visibility { "shared_users" }
    end

    trait :public_note do
      visibility { "public_note" }
    end
  end
end
