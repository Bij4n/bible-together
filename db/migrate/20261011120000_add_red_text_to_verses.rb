# Jesus's words in a verse, on their own, so search can match inside
# them instead of anywhere in a verse he speaks in. NULL for the
# verses with no red text. Kept in step by the importer, the KJV
# mirror and the red-letter patch; filled here for verses already
# imported.
class AddRedTextToVerses < ActiveRecord::Migration[8.1]
  class MigrationVerse < ActiveRecord::Base
    self.table_name = "verses"
  end

  def up
    add_column :verses, :red_text, :text

    MigrationVerse.where("red_letter_ranges <> '[]'::jsonb").find_each do |verse|
      text = verse.red_letter_ranges.map { |from, to| verse.body_text[from...to] }.join(" ").presence
      verse.update_columns(red_text: text)
    end
  end

  def down
    remove_column :verses, :red_text
  end
end
