# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Preferences (custom)
      t.string :ui_locale,  null: false, default: "en"
      t.string :theme,      null: false, default: "system"
      t.references :default_translation, foreign_key: { to_table: :translations }
      t.string :display_name

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true

    # Optional but globally unique when set — case-insensitive.
    add_index :users,
              "lower(display_name)",
              unique: true,
              where: "display_name IS NOT NULL",
              name: "index_users_on_lower_display_name"

    # Belt-and-suspenders enum enforcement in case application code is
    # bypassed.
    add_check_constraint :users, "ui_locale IN ('en', 'es')",
                         name: "users_ui_locale_check"
    add_check_constraint :users, "theme IN ('light', 'dark', 'system')",
                         name: "users_theme_check"
    add_check_constraint :users, "char_length(display_name) <= 60",
                         name: "users_display_name_length_check"
  end
end
