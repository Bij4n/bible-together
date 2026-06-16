class RemoveThemeFromUsers < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :users, :theme, :string, default: "system", null: false
    end
  end
end
