class CreateHouseholds < ActiveRecord::Migration[7.2]
  def change
    create_table :households, id: :uuid do |t|
      t.string :name, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
