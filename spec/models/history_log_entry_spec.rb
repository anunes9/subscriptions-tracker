require 'rails_helper'

# == Schema Information
#
# Table name: history_log_entries
#
#  id              :uuid             not null, primary key
#  amount          :decimal(12, 2)   not null
#  confirmed_at    :datetime
#  currency        :string           not null
#  is_estimated    :boolean          default(FALSE), not null
#  period          :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  subscription_id :uuid             not null
#
# Indexes
#
#  index_history_log_entries_on_subscription_id             (subscription_id)
#  index_history_log_entries_on_subscription_id_and_period  (subscription_id,period) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#
RSpec.describe HistoryLogEntry, type: :model do
  it "defaults is_estimated to false" do
    entry = HistoryLogEntry.create!(subscription: create_subscription, period: "2026-09", amount: 9.99, currency: "EUR")

    expect(entry.is_estimated).to eq(false)
  end

  it "only allows one entry per subscription per period" do
    subscription = create_subscription
    HistoryLogEntry.create!(subscription: subscription, period: "2026-09", amount: 9.99, currency: "EUR")

    duplicate = HistoryLogEntry.new(subscription: subscription, period: "2026-09", amount: 12.99, currency: "EUR")

    expect(duplicate).not_to be_valid
  end

  it "allows the same period across different subscriptions" do
    subscription_a = create_subscription
    subscription_b = create_subscription
    HistoryLogEntry.create!(subscription: subscription_a, period: "2026-09", amount: 9.99, currency: "EUR")

    other = HistoryLogEntry.new(subscription: subscription_b, period: "2026-09", amount: 9.99, currency: "EUR")

    expect(other).to be_valid
  end
end
