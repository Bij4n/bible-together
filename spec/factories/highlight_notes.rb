FactoryBot.define do
  factory :highlight_note do
    association :highlight
    association :note
  end
end
