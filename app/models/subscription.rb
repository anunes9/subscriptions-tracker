# == Schema Information
#
# Table name: subscriptions
#
#  id                         :uuid             not null, primary key
#  amount_type                :string           not null
#  billing_anchor_date        :date             not null
#  billing_cycle              :string           not null
#  color_override             :string
#  currency                   :string           not null
#  custom_reminder_lead_days  :integer
#  icon_override              :string
#  name                       :string           not null
#  notes                      :text
#  rating                     :integer
#  status                     :string           default("active"), not null
#  subscription_type          :string           default("regular"), not null
#  tag                        :string
#  trial_end_date             :date
#  visibility                 :string           default("shared"), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  category_id                :uuid             not null
#  household_id               :uuid
#  service_directory_entry_id :uuid
#  user_id                    :uuid             not null
#
# Indexes
#
#  index_subscriptions_on_category_id                 (category_id)
#  index_subscriptions_on_household_id                (household_id)
#  index_subscriptions_on_service_directory_entry_id  (service_directory_entry_id)
#  index_subscriptions_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (household_id => households.id)
#  fk_rails_...  (service_directory_entry_id => service_directory_entries.id)
#  fk_rails_...  (user_id => users.id)
#
class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :service_directory_entry, optional: true
  belongs_to :category
  belongs_to :household, optional: true
  has_many :history_log_entries, dependent: :destroy
  has_many :reminder_logs, dependent: :destroy

  enum :currency, { eur: "EUR", usd: "USD" }
  enum :billing_cycle, { monthly: "monthly", yearly: "yearly" }
  enum :amount_type, { fixed: "fixed", variable: "variable" }
  enum :subscription_type, { regular: "regular", trial: "trial" }, default: :regular
  enum :status, { active: "active", paused: "paused", cancelled: "cancelled" }, default: :active
  enum :tag, { essential: "essential", nice_to_have: "nice_to_have" }
  enum :visibility, { private_visibility: "private", shared: "shared" }, default: :shared

  validates :name, presence: true
  validates :billing_anchor_date, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
end
