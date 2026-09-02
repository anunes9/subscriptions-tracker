# == Schema Information
#
# Table name: exchange_rates
#
#  id            :uuid             not null, primary key
#  from_currency :string           not null
#  rate          :decimal(12, 6)   not null
#  rate_date     :date             not null
#  to_currency   :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exchange_rates_on_date_and_currencies  (rate_date,from_currency,to_currency) UNIQUE
#
class ExchangeRate < ApplicationRecord
  validates :rate_date, :from_currency, :to_currency, :rate, presence: true
  validates :from_currency, uniqueness: { scope: [ :rate_date, :to_currency ] }
end
