class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :users, :username, :string
    add_index :users, "lower(username)",
              unique: true,
              where: "username IS NOT NULL",
              name: "index_users_on_lower_username",
              algorithm: :concurrently
  end
end
