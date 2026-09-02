class CreateHistoryLogEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :history_log_entries, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.string :period, null: false
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.string :currency, null: false
      t.boolean :is_estimated, null: false, default: false
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :history_log_entries, [ :subscription_id, :period ], unique: true
  end
end
