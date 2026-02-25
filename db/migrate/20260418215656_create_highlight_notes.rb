class CreateHighlightNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :highlight_notes do |t|
      t.references :highlight, null: false, foreign_key: true
      t.references :note,      null: false, foreign_key: true

      t.timestamps
    end

    add_index :highlight_notes, [ :highlight_id, :note_id ], unique: true
  end
end
