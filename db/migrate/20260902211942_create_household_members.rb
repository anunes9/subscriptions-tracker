class CreateHouseholdMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :household_members, id: :uuid do |t|
      t.references :household, null: false, foreign_key: true, type: :uuid
      # One active household membership per user in v1 (data-model.md 2.7).
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :role, null: false, default: "member"
      t.datetime :joined_at, null: false

      t.timestamps
    end
  end
end
