class CreateOneTimeExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :one_time_expenses, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.string :currency, null: false
      t.date :expense_date, null: false
      t.text :note
      # Nullable: see data-model.md 2.7/4.13.
      t.references :household, null: true, foreign_key: true, type: :uuid
      t.string :visibility, null: false, default: "shared"

      t.timestamps
    end
  end
end
