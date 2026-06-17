class AddProfilePhotoAndMarkupPrefs < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :highlight_toolbar_colors, :jsonb,
               default: %w[yellow green blue rose orange purple], null: false
    add_column :users, :highlight_color_labels, :jsonb, default: {}, null: false
    add_column :users, :default_note_color, :string, default: "violet", null: false

    add_column :notes, :color, :string, default: "violet", null: false
    add_column :notes, :label, :string, limit: 40
  end
end
