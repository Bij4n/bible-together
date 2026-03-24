class CreateFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :flags do |t|
      t.references :flaggable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.text :details
      t.datetime :resolved_at
      t.references :resolved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :flags, [ :user_id, :flaggable_type, :flaggable_id ],
              unique: true,
              name: "index_flags_uniqueness"
    add_index :flags, :resolved_at
  end
end
