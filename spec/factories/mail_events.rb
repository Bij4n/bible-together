FactoryBot.define do
  factory :mail_event do
    sequence(:svix_id) { |n| "msg_#{n}" }
    event_type { "email.bounced" }
    email_id { "56761188-7520-42d8-8898-ff6fc54ce618" }
    recipient { "hello@bible-together.org" }
    subject { "Contact form — Ruth" }
    reason { "Permanent / Suppressed / Recipient's email on suppression list" }
    occurred_at { Time.current }
    payload { { "type" => "email.bounced" } }
  end
end
