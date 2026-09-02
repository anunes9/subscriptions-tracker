require 'rails_helper'

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
RSpec.describe ReminderLog, type: :model do
  it "allows email and in_app channels" do
    subscription = create_subscription
    attrs = { subscription: subscription, trigger_reason: "renewal", sent_at: Time.current }

    expect(ReminderLog.new(attrs.merge(channel: "email"))).to be_valid
    expect(ReminderLog.new(attrs.merge(channel: "in_app"))).to be_valid
  end

  it "allows renewal and trial_end trigger reasons" do
    subscription = create_subscription
    attrs = { subscription: subscription, channel: "email", sent_at: Time.current }

    expect(ReminderLog.new(attrs.merge(trigger_reason: "renewal"))).to be_valid
    expect(ReminderLog.new(attrs.merge(trigger_reason: "trial_end"))).to be_valid
  end
end
