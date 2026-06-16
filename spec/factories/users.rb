FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "reader#{n}@bible-together.test" }
    password { "correct horse battery staple" }
    password_confirmation { "correct horse battery staple" }
    ui_locale { "en" }

    trait :with_spanish_locale do
      ui_locale { "es" }
    end

    trait :with_display_name do
      sequence(:display_name) { |n| "Reader#{n}" }
    end
  end
end
