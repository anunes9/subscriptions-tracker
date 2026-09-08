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
  # yearly cycles log by the exact anchor date.
  def current_period
    monthly? ? Date.current.strftime("%Y-%m") : billing_anchor_date.to_s
  end

  # The most recently logged period, whichever came first — the carry-
  # forward source for both the Variable estimate and the Fixed auto-log
  # (PRD 4.1.1: "carried forward from the last known period, whether that
  # period was itself Fixed or Variable").
  def latest_history_entry
    history_log_entries.order(period: :desc).first
  end

  # Ensures the current period has a log entry, so "what did I spend this
  # period" always has an answer even before the user has touched anything
  # this period. A recurring job will eventually call this proactively as
  # each period rolls over (Phase 2's PeriodRolloverJob); for now it runs
  # reactively whenever a subscription is read (see SubscriptionsController).
  #
  # Fixed subscriptions log the carried-forward amount as a confirmed
  # actual — the fixed price *is* this period's charge by definition, with
  # no user confirmation step (PRD: "invisible to the user in normal use").
  # Variable subscriptions log it as an unconfirmed estimate, since only the
  # user confirming/editing it makes it an actual.
  #
  # Returns nil if there's nothing to carry forward from yet (a subscription
  # with no history at all — shouldn't happen once ticket 1.3's add flow has
  # run, but a subscription created without an initial amount is possible
  # via edits that never set one).
  def ensure_current_period_logged!
    history_log_entries.find_by(period: current_period) || begin
      carry_forward = latest_history_entry
      return nil unless carry_forward

      history_log_entries.create!(
        period: current_period,
        amount: carry_forward.amount,
        currency: currency,
        is_estimated: variable?,
        confirmed_at: variable? ? nil : Time.current
      )
    end
  end

  # Normalizes an amount to its monthly-equivalent cost (PRD 4.3): yearly
  # subscriptions divide by 12 so they can be combined with monthly ones
  # into a single total; monthly amounts are already there. Takes the
  # amount as an argument rather than resolving it itself, since callers
  # already have it (e.g. from ensure_current_period_logged!) and a pure
  # calculation is simpler to test and reuse than one with a DB-writing
  # side effect baked in.
  def monthly_equivalent(amount)
    return nil unless amount

    yearly? ? (amount / 12) : amount
  end
end
