class CreateExchangeRates < ActiveRecord::Migration[7.2]
  def change
    create_table :exchange_rates, id: :uuid do |t|
      t.date :rate_date, null: false
      t.string :from_currency, null: false
      t.string :to_currency, null: false
      t.decimal :rate, null: false, precision: 12, scale: 6

      t.timestamps
    end

    add_index :exchange_rates, [ :rate_date, :from_currency, :to_currency ], unique: true, name: "index_exchange_rates_on_date_and_currencies"
  end
end
