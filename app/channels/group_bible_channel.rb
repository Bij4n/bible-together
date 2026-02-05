# Custom Turbo Streams channel gating subscriptions on group membership.
# Extends Turbo::StreamsChannel so broadcasts use the same signed-stream
# plumbing; the only addition is decoding the streamable tuple to find
# the Group the user is trying to subscribe to, then rejecting when
# current_user isn't a member.
#
# View side:
#   <%= turbo_stream_from @group, "bible", translation_code, book_osis,
#                         chapter_number, channel: "GroupBibleChannel" %>
#
# Server side broadcasts use the same streamable array — see
# Turbo::Broadcastable / Turbo::StreamsChannel.broadcast_*_to.
class GroupBibleChannel < Turbo::StreamsChannel
  def subscribed
    stream_name = verified_stream_name_from_params
    group = group_from_stream_name(stream_name)

    if stream_name.present? && group&.member?(current_user)
      stream_from stream_name
    else
      reject
    end
  end

  private

  # Turbo base64-encodes each streamable (so GlobalID slashes don't
  # collide with the ":" separator), then joins with ":". The group
  # GID lives in the leading segment — base64-decode, then locate.
  def group_from_stream_name(name)
    return nil if name.blank?

    first_segment = name.to_s.split(":").first
    return nil if first_segment.blank?

    decoded = Base64.urlsafe_decode64(first_segment)
    GlobalID::Locator.locate(decoded)
  rescue StandardError
    nil
  end
end
