class User < ApplicationRecord
  UI_LOCALES = %w[en es].freeze
  THEMES     = %w[light dark system].freeze
  DISPLAY_NAME_MAX = 60

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :default_translation, class_name: "Translation", optional: true

  has_many :highlights, dependent: :destroy
  has_many :notes, dependent: :destroy

  validates :ui_locale, inclusion: { in: UI_LOCALES }
  validates :theme,     inclusion: { in: THEMES }
  validates :display_name,
            length: { maximum: DISPLAY_NAME_MAX },
            uniqueness: { case_sensitive: false, allow_blank: true }
end
