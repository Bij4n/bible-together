FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "reader#{n}@open-bible.test" }
    password { "correct horse battery staple" }
    password_confirmation { "correct horse battery staple" }
    ui_locale { "en" }
    theme { "system" }

    trait :with_spanish_locale do
      ui_locale { "es" }
    end

    trait :with_dark_theme do
      theme { "dark" }
    end

    trait :with_light_theme do
      theme { "light" }
    end

    trait :with_display_name do
      sequence(:display_name) { |n| "Reader#{n}" }
    end
  end
end
