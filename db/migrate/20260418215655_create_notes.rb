class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :visibility, null: false, default: 0

      t.timestamps
    end
  end
end
