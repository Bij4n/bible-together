require "rails_helper"

RSpec.describe GroupBibleChannel, type: :channel do
  let(:owner)    { create(:user) }
  let(:member)   { create(:user) }
  let(:outsider) { create(:user) }
  let(:group)    { create(:group, owner: owner) }

  before { create(:membership, user: member, group: group, role: :member) }

  def signed_name_for(group, translation = "KJV", book = "John", chapter = 3)
    Turbo::StreamsChannel.signed_stream_name([ group, "bible", translation, book, chapter ])
  end

  it "accepts a subscription from the owner" do
    stub_connection current_user: owner
    subscribe signed_stream_name: signed_name_for(group)
    expect(subscription).to be_confirmed
  end

  it "accepts a subscription from a non-owner member" do
    stub_connection current_user: member
    subscribe signed_stream_name: signed_name_for(group)
    expect(subscription).to be_confirmed
  end

  it "rejects a non-member" do
    stub_connection current_user: outsider
    subscribe signed_stream_name: signed_name_for(group)
    expect(subscription).to be_rejected
  end

  it "rejects when the signed stream name can't be verified" do
    stub_connection current_user: owner
    subscribe signed_stream_name: "not-a-valid-signature"
    expect(subscription).to be_rejected
  end

  it "scopes streams per group-chapter tuple" do
    stub_connection current_user: owner
    subscribe signed_stream_name: signed_name_for(group, "KJV", "John", 3)
    chapter_three_stream = Turbo::StreamsChannel.send(:stream_name_from,
                                                      [ group, "bible", "KJV", "John", 3 ])
    chapter_four_stream  = Turbo::StreamsChannel.send(:stream_name_from,
                                                      [ group, "bible", "KJV", "John", 4 ])
    expect(subscription.streams).to include(chapter_three_stream)
    expect(subscription.streams).not_to include(chapter_four_stream)
  end
end
