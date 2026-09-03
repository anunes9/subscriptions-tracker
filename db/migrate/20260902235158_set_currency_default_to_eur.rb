class SetCurrencyDefaultToEur < ActiveRecord::Migration[7.2]
  def change
    change_column_default :subscriptions, :currency, from: nil, to: "EUR"
    change_column_default :one_time_expenses, :currency, from: nil, to: "EUR"
  end
end
