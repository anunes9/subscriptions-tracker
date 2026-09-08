# == Schema Information
#
# Table name: subscriptions
# Database name: primary
#
#  id                         :uuid             not null, primary key
#  amount_type                :string           not null
#  billing_anchor_date        :date             not null
#  billing_cycle              :string           not null
#  color_override             :string
#  currency                   :string           default("EUR"), not null
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

  enum :billing_cycle, { monthly: "monthly", yearly: "yearly" }
  enum :amount_type, { fixed: "fixed", variable: "variable" }
  enum :subscription_type, { regular: "regular", trial: "trial" }, default: :regular
  enum :status, { active: "active", paused: "paused", cancelled: "cancelled" }, default: :active
  enum :tag, { essential: "essential", nice_to_have: "nice_to_have" }
  enum :visibility, { private_visibility: "private", shared: "shared" }, default: :shared

  validates :name, presence: true
  validates :billing_anchor_date, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  # EUR-only for now; USD/multi-currency support is deferred.
  validates :currency, inclusion: { in: %w[EUR] }

  # The history log's period key for the period the subscription is currently
  # in (PRD 4.1.1 / data model 2.5) — monthly cycles log by calendar month,
  # yearly cycles log by the exact anchor date. Ticket 1.4 builds the
  # recurring rollover/estimate engine on top of this; for now it's what lets
  # add/edit record the period's amount at all.
  def current_period
    monthly? ? Date.current.strftime("%Y-%m") : billing_anchor_date.to_s
  end
end
