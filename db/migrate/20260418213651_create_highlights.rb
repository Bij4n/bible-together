class CreateHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :highlights do |t|
      t.references :user, null: false, foreign_key: true
      t.references :translation, null: false, foreign_key: true
      t.string :osis_ref, null: false
      t.integer :color, null: false, default: 0

      t.timestamps
    end

    # Supports prefix-LIKE queries for "all highlights in this chapter" —
    # `WHERE osis_ref LIKE 'Bible.KJV.John.3.%'` hits the B-tree index.
    add_index :highlights, :osis_ref
    add_index :highlights, [ :user_id, :osis_ref, :color ],
              unique: true,
              name: "index_highlights_on_user_osis_ref_color"
  end
end
