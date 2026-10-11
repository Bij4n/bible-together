# A study can work through one of the curated lists (the parables, the
# encounters, the sayings, or a theme) passage by passage.
# reading_list names the list; current_passage is the slug the study is
# on. Both nullable: an ordinary study has neither.
class AddReadingListToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :reading_list, :string
    add_column :groups, :current_passage, :string
  end
end
