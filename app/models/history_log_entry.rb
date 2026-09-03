# == Schema Information
#
# Table name: history_log_entries
# Database name: primary
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
class HistoryLogEntry < ApplicationRecord
  belongs_to :subscription

  validates :period, presence: true, uniqueness: { scope: :subscription_id }
  validates :amount, presence: true
  validates :currency, presence: true
end
