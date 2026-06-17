class User < ApplicationRecord
  UI_LOCALES = %w[en es].freeze
  DISPLAY_NAME_MAX = 60
  USERNAME_FORMAT = /\A[a-zA-Z0-9_]{3,30}\z/
  BIO_MAX = 300
  NOTE_COLOR_OPTIONS = Note::NOTE_COLORS

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  belongs_to :default_translation, class_name: "Translation", optional: true

  has_many :highlights, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :upvotes, dependent: :destroy

  has_many :forum_threads, dependent: :destroy
  has_many :forum_posts, dependent: :destroy

  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :owned_groups, class_name: "Group", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner

  # Polymorphic note shares keyed on this user (shareable).
  has_many :note_shares, as: :shareable, dependent: :destroy

  # Outbound email invites this user has sent — Sprint 23.1.
  has_many :sent_group_invitations,
           class_name: "GroupInvitation",
           foreign_key: :invited_by_id,
           dependent: :destroy,
           inverse_of: :invited_by

  # Follows (Sprint R5). Two directed edge sets; the intersection is
  # #friends — the audience of the friends_note visibility (R6).
  has_many :follows, foreign_key: :follower_id, dependent: :destroy, inverse_of: :follower
  has_many :following, through: :follows, source: :followed
  has_many :reverse_follows, class_name: "Follow", foreign_key: :followed_id,
                             dependent: :destroy, inverse_of: :followed
  has_many :followers, through: :reverse_follows, source: :follower

  validates :ui_locale, inclusion: { in: UI_LOCALES }
  validates :display_name,
            length: { maximum: DISPLAY_NAME_MAX },
            uniqueness: { case_sensitive: false, allow_blank: true }
  validates :username,
            allow_blank: true,
            format: { with: USERNAME_FORMAT },
            uniqueness: { case_sensitive: false }
  validates :bio, length: { maximum: BIO_MAX }
  validates :default_note_color, inclusion: { in: NOTE_COLOR_OPTIONS }
  validate :highlight_toolbar_colors_are_valid
  validate :highlight_toolbar_colors_present, if: -> { highlight_toolbar_colors_changed? }
  validate :acceptable_avatar

  def toolbar_colors
    chosen = Array(highlight_toolbar_colors).select { |c| Highlight::COLORS.include?(c) }
    chosen.presence || Highlight::DEFAULT_TOOLBAR_COLORS
  end

  def highlight_label_for(color)
    highlight_color_labels.to_h[color.to_s].presence
  end

  # Profile stats treat visibility as private-vs-public: a note is
  # "private" unless it is published to everyone. Only-me, friends,
  # specific people, and study/group shares all count as private —
  # they're limited audiences, not the open web.
  def note_stats
    total = notes.count
    public_count = notes.public_note.count
    {
      total: total,
      public: public_count,
      private: total - public_count
    }
  end

  def note_color_label(color)
    return color.capitalize if color.blank?

    I18n.t("notes.colors.#{color}", default: color.capitalize)
  end

  def follow!(user)
    follows.find_or_create_by!(followed: user)
  end

  def unfollow!(user)
    follows.where(followed: user).destroy_all
  end

  def following?(user)
    follows.exists?(followed: user)
  end

  # Mutual follows. Two index-backed subqueries (the through
  # associations' id sets) intersected — composes cleanly as a
  # relation for R6's visible_to branch (friends.select(:id)).
  def friends
    User.where(id: following.select(:id)).where(id: followers.select(:id))
  end

  def friends_with?(user)
    friends.exists?(user.id)
  end

  # Public-facing author label for notes, comments, and group-bible
  # attributions. Prefers display_name; falls back to the email
  # local-part so we never expose the full email address to groupmates.
  def author_name
    return display_name if display_name.present?

    email.to_s.split("@").first.presence || email
  end

  # Profile URLs use the username handle when set, falling back to the id
  # for users who haven't picked one. Resolve either form via find_by_handle!.
  def to_param
    username.presence || id.to_s
  end

  def self.find_by_handle!(key)
    find_by("lower(username) = ?", key.to_s.downcase) || find(key)
  end

  private

  def highlight_toolbar_colors_are_valid
    return if highlight_toolbar_colors.blank?

    invalid = Array(highlight_toolbar_colors).reject(&:blank?) - Highlight::COLORS
    return if invalid.empty?

    errors.add(:highlight_toolbar_colors, :invalid)
  end

  def highlight_toolbar_colors_present
    if Array(highlight_toolbar_colors).reject(&:blank?).empty?
      errors.add(:highlight_toolbar_colors, :blank)
    end
  end

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, or WebP image")
    end
    errors.add(:avatar, "must be smaller than 2 MB") if avatar.byte_size > 2.megabytes
  end
end
