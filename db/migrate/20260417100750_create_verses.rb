class CreateVerses < ActiveRecord::Migration[8.1]
  def change
    create_table :verses do |t|
      t.references :chapter, null: false, foreign_key: true
      t.integer :number, null: false
      t.text :body_text, null: false
      t.text :body_html, null: false
      t.jsonb :red_letter_ranges, null: false, default: []
      t.string :osis_ref, null: false

      t.timestamps
    end

    add_index :verses, [ :chapter_id, :number ], unique: true
    add_index :verses, :osis_ref, unique: true
  end
end
