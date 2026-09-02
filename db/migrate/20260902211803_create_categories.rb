class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name, null: false
      t.string :icon
      t.string :color
      # Nullable: null for the ~9 global preset categories, set for a user's custom ones.
      t.references :user, null: true, foreign_key: true, type: :uuid
      t.boolean :is_preset, null: false, default: false

      t.timestamps
    end
  end
end
