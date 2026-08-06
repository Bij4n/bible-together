require "rails_helper"

# /contact is a fully public flow — no sign-in needed. rack_test is
# enough: the form is a plain POST with no Stimulus behaviour. The
# submission is persisted as a ContactMessage, so this spec asserts the
# row lands rather than trusting the notification email.
RSpec.describe "Public contact flow", type: :system do
  it "renders the form and the direct email address" do
    visit "/contact"

    expect(page).to have_content(I18n.t("contact.heading"))
    expect(page).to have_content("hello@bible-together.org")

    expect(page).to have_css('form[action="/contact"]', visible: :all)
    expect(page).to have_css('input[name="contact_message[email]"]', visible: :all)
    expect(page).to have_css('textarea[name="contact_message[message]"]', visible: :all)
  end

  # Asserts the markup that hides the field rather than Capybara
  # visibility: rack_test applies no stylesheets, so a .sr-only element
  # still reports as visible. The wrapper class, aria-hidden, and
  # tabindex are what actually keep it away from humans, screen readers,
  # and keyboard navigation.
  it "carries a honeypot field wrapped so humans and screen readers skip it" do
    visit "/contact"

    expect(page).to have_css('.sr-only[aria-hidden="true"] input[name="website"]', visible: :all)
    expect(page).to have_css('input[name="website"][tabindex="-1"]', visible: :all)
  end

  it "persists the submission and confirms it to the visitor" do
    visit "/contact"

    fill_in I18n.t("contact.name_label"), with: "Ruth"
    fill_in I18n.t("contact.email_label"), with: "ruth@example.com"
    fill_in I18n.t("contact.message_label"), with: "A question about a verse."
    click_on I18n.t("contact.submit")

    expect(page).to have_current_path("/contact")
    expect(page).to have_content(I18n.t("contact.success"))

    record = ContactMessage.last
    expect(record.name).to eq("Ruth")
    expect(record.email).to eq("ruth@example.com")
    expect(record.message).to eq("A question about a verse.")
  end

  it "re-renders with an error and keeps nothing when the message is blank" do
    visit "/contact"

    fill_in I18n.t("contact.email_label"), with: "ruth@example.com"
    click_on I18n.t("contact.submit")

    expect(page).to have_content(I18n.t("contact.error"))
    expect(ContactMessage.count).to eq(0)
  end
end
