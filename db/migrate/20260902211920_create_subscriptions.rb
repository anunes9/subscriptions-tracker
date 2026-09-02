class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      # Nullable: null for custom/unmatched services.
      t.references :service_directory_entry, null: true, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :currency, null: false
      t.string :billing_cycle, null: false
      t.string :amount_type, null: false
      t.string :subscription_type, null: false, default: "regular"
      t.string :status, null: false, default: "active"
      t.date :billing_anchor_date, null: false
      # Nullable: only set when subscription_type = trial.
      t.date :trial_end_date
      t.integer :rating
      t.string :tag
      t.string :icon_override
      t.string :color_override
      t.text :notes
      t.integer :custom_reminder_lead_days
      # Nullable: set only if the owning user belongs to a household.
      t.references :household, null: true, foreign_key: true, type: :uuid
      t.string :visibility, null: false, default: "shared"

      t.timestamps
    end
  end
end
