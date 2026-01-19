class CreateChapters < ActiveRecord::Migration[8.1]
  def change
    create_table :chapters do |t|
      t.references :book, null: false, foreign_key: true
      t.integer :number, null: false
      t.integer :verse_count, null: false, default: 0

      t.timestamps
    end

    add_index :chapters, [ :book_id, :number ], unique: true
  end
end
