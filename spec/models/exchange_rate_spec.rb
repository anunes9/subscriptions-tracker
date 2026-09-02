require 'rails_helper'

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
RSpec.describe ExchangeRate, type: :model do
  it "only allows one snapshot per date and currency pair" do
    ExchangeRate.create!(rate_date: Date.current, from_currency: "EUR", to_currency: "USD", rate: 1.08)

    duplicate = ExchangeRate.new(rate_date: Date.current, from_currency: "EUR", to_currency: "USD", rate: 1.09)

    expect(duplicate).not_to be_valid
  end

  it "allows the same date with a different currency pair" do
    ExchangeRate.create!(rate_date: Date.current, from_currency: "EUR", to_currency: "USD", rate: 1.08)

    other = ExchangeRate.new(rate_date: Date.current, from_currency: "USD", to_currency: "EUR", rate: 0.93)

    expect(other).to be_valid
  end
end
