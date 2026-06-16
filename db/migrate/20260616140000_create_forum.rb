class CreateForum < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_threads do |t|
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :hidden_at
      t.references :hidden_by, foreign_key: { to_table: :users }
      t.datetime :last_posted_at
      t.timestamps
    end
    add_index :forum_threads, :last_posted_at

    create_table :forum_posts do |t|
      t.references :forum_thread, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :hidden_at
      t.references :hidden_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
