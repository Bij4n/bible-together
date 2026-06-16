class AddBioAndCommentNotificationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio, :text
    add_column :users, :email_on_comment, :boolean, default: true, null: false
  end
end
