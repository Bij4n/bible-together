FactoryBot.define do
  factory :highlight do
    association :user
    association :translation
    osis_ref { "Bible.KJV.John.3.16" }
    color { "gold" }
  end
end
