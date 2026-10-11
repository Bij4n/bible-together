# What a reader, or a study, reads by default: the whole Bible (0) or
# Highlighted in Red (1). Additive, with a default, so existing rows
# keep reading the whole Bible.
class AddStudyFocusToUsersAndGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :study_focus, :integer, default: 0, null: false
    add_column :groups, :focus, :integer, default: 0, null: false
  end
end
