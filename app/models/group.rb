class Group < ApplicationRecord
  PRIVACIES = { private_group: 0, invite_only: 1, open_group: 2 }.freeze
  INVITATION_CODE_FORMAT = /\A[A-Z0-9]{6,8}\z/

  enum :privacy, PRIVACIES

  # What the study reads together: the whole Bible, or Highlighted in
  # Red (Jesus's words, under the red lens). Integer-backed, so this
  # hash is append-only.
  FOCUSES = { bible: 0, red: 1 }.freeze
  enum :focus, FOCUSES, prefix: true, validate: true

  belongs_to :owner, class_name: "User"
  # delete_all (not :destroy) bypasses the at-least-one-owner callback on
  # Membership — if the whole group is going away, there's nothing to
  # preserve. Individual membership destroys still hit the callback.
  has_many :memberships, dependent: :delete_all
  has_many :members, through: :memberships, source: :user

  has_many :note_shares, as: :shareable, dependent: :destroy

  # Email-based invitations — Sprint 23.1. Augments the
  # invitation_code flow with sent + tokenized join links.
  has_many :group_invitations, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :invitation_code,
            uniqueness: true,
            format: { with: INVITATION_CODE_FORMAT },
            allow_blank: true

  # Every group has an owner Membership so `user.groups` transparently
  # spans both owned and joined groups in a single association.
  after_create :ensure_owner_membership

  def member?(user)
    return false unless user

    owner_id == user.id || memberships.exists?(user_id: user.id)
  end

  # Owners and admins can manage the group: edit it, invite/cancel
  # invitations, and remove plain members. Destroying the group and
  # changing member roles stay owner-only (enforced in the controllers).
  def manager?(user)
    return false unless user

    owner_id == user.id || memberships.where(role: [ :owner, :admin ]).exists?(user_id: user.id)
  end

  # Member notes shared with this study (club feed on the show page).
  def recent_member_notes(limit: 25)
    Note.shared_with_group(self)
        .includes(:user, highlights: { highlight_notes: :note })
        .order(created_at: :desc)
        .limit(limit)
  end

  # Most recently touched highlight shared with the study — drives the
  # "reading together" card. Falls back to where the study starts when
  # empty.
  def reading_together_location
    highlight = Highlight.joins(highlight_notes: { note: :note_shares })
                         .where(note_shares: { shareable_type: "Group", shareable_id: id })
                         .order("highlights.updated_at DESC")
                         .first
    return starting_location unless highlight

    parts = highlight.osis_ref.split(".")
    return starting_location if parts.size < 4

    { translation: parts[1].downcase, book: parts[2].downcase, chapter: parts[3].to_i }
  rescue StandardError
    { translation: "kjv", book: "gen", chapter: 1 }
  end

  # Genesis 1 in the KJV, or for a study of Highlighted in Red the
  # first chapter with any of his words.
  def starting_location
    first_red = focus_red? && (kjv = Translation.find_by(code: "KJV")) && Bible::RedLetterIndex.for(kjv).first
    return { translation: "kjv", book: "gen", chapter: 1 } unless first_red

    { translation: "kjv", book: first_red.book.downcase, chapter: first_red.number }
  end

  def self.generate_invitation_code
    alphabet = ("A".."Z").to_a + ("0".."9").to_a
    length   = 6 + rand(3) # 6..8
    Array.new(length) { alphabet.sample }.join
  end

  private

  def ensure_owner_membership
    memberships.find_or_create_by!(user: owner) do |m|
      m.role = :owner
    end
  end
end
