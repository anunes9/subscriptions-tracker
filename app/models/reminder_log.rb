# == Schema Information
#
# Table name: reminder_logs
#
#  id              :uuid             not null, primary key
#  channel         :string           not null
#  sent_at         :datetime         not null
#  trigger_reason  :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  subscription_id :uuid             not null
#
# Indexes
#
#  index_reminder_logs_on_subscription_id  (subscription_id)
#
# Foreign Keys
#
#  fk_rails_...  (subscription_id => subscriptions.id)
#
class ReminderLog < ApplicationRecord
  belongs_to :subscription

  enum :channel, { email: "email", in_app: "in_app" }
  enum :trigger_reason, { renewal: "renewal", trial_end: "trial_end" }

  validates :sent_at, presence: true
end
