class Comment < ApplicationRecord
  MAX_DEPTH = 3
  BODY_MAX  = 2_000

  belongs_to :note
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true, length: { maximum: BODY_MAX }
  validate  :parent_is_not_self

  # Sibling-on-overflow: a reply to a depth-MAX comment becomes a sibling
  # of that comment (child of its parent), so threading flattens rather
  # than breaking the chain.
  before_validation :siblingize_if_over_max_depth
  before_save       :cache_depth

  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered_for_display, -> { order(:created_at) }

  scope :visible_to, ->(user) {
    joins(:note).merge(Note.visible_to(user))
  }

  # Broadcasts piggyback on the Sprint 5 GroupBibleChannel: append the
  # new comment into #comments_thread_<note_id> on every group-chapter
  # stream the parent note shows up on. Direct-user shares don't
  # broadcast in Sprint 6 — per-user channels are a future sprint.
  after_create_commit  :broadcast_comment_created
  before_destroy       :snapshot_broadcast_targets
  after_destroy_commit :broadcast_comment_destroyed

  private

  def siblingize_if_over_max_depth
    while parent && (parent.depth || 0) >= MAX_DEPTH
      self.parent = parent.parent
    end
  end

  def cache_depth
    self.depth = parent ? [ (parent.depth || 0) + 1, MAX_DEPTH ].min : 0
  end

  def parent_is_not_self
    return if parent_id.nil?

    errors.add(:parent_id, "can't be the comment itself") if parent_id == id
  end

  def broadcast_comment_created
    target_streams.each do |stream|
      Turbo::StreamsChannel.broadcast_append_to(
        *stream,
        target: "comments_thread_#{note_id}",
        partial: "comments/comment",
        locals: { comment: self }
      )
    end
  end

  def snapshot_broadcast_targets
    @broadcast_streams_snapshot = target_streams
    @broadcast_dom_id_snapshot  = ActionView::RecordIdentifier.dom_id(self)
  end

  def broadcast_comment_destroyed
    Array(@broadcast_streams_snapshot).each do |stream|
      Turbo::StreamsChannel.broadcast_remove_to(
        *stream,
        target: @broadcast_dom_id_snapshot
      )
    end
  end

  # Returns an array of streamable tuples (one per group × chapter the
  # note lives on). Broadcasting a comment to all of them hits every
  # viewer who can see the underlying note.
  def target_streams
    groups = note.shared_groups.to_a
    return [] if groups.empty?

    chapters = note.highlights.map do |h|
      ref = OsisRef.parse(h.osis_ref)
      [ ref.translation_code, ref.start_book, ref.start_chapter ]
    end.uniq

    groups.flat_map do |group|
      chapters.map do |(translation, book, chapter)|
        [ group, "bible", translation, book, chapter ]
      end
    end
  end
end
