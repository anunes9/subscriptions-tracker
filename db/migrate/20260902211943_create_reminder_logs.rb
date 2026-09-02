class CreateReminderLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :reminder_logs, id: :uuid do |t|
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.string :channel, null: false
      t.string :trigger_reason, null: false
      t.datetime :sent_at, null: false

      t.timestamps
    end
  end
end
