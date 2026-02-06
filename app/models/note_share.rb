class NoteShare < ApplicationRecord
  include GroupBibleBroadcastable

  belongs_to :note
  belongs_to :shareable, polymorphic: true

  validates :shareable_type, inclusion: { in: %w[User Group] }
  validates :note_id, uniqueness: { scope: [ :shareable_type, :shareable_id ] }

  after_create_commit  :broadcast_share_created
  before_destroy       :snapshot_share
  after_destroy_commit :broadcast_share_destroyed

  private

  # Sharing with a group means: re-render every affected verse on that
  # group's bible view (so the highlight colour appears) + append the
  # note into #group_notes_list. Sharing with a user doesn't broadcast —
  # direct recipients see the note the next time they load /notes/:id.
  def broadcast_share_created
    return unless shareable_type == "Group" && shareable

    verses = note.highlights.flat_map(&:affected_verses).uniq
    broadcast_verse_replace_to_groups([ shareable ], verses)
    broadcast_note_append_to_groups([ shareable ], note)
  end

  def snapshot_share
    @snapshot_shareable = shareable
    @snapshot_note      = note
    @snapshot_verses    = note&.highlights&.flat_map(&:affected_verses)&.uniq || []
  end

  def broadcast_share_destroyed
    return unless @snapshot_shareable.is_a?(Group)

    broadcast_verse_replace_to_groups([ @snapshot_shareable ], @snapshot_verses)
    broadcast_note_remove_to_groups([ @snapshot_shareable ], @snapshot_note) if @snapshot_note
  end
end
