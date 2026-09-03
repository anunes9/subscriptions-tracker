require 'rails_helper'

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
RSpec.describe Subscription, type: :model do
  it "defaults to active, regular, shared, and EUR" do
    subscription = create_subscription

    expect(subscription.status).to eq("active")
    expect(subscription.subscription_type).to eq("regular")
    expect(subscription.visibility).to eq("shared")
    expect(subscription.currency).to eq("EUR")
  end

  it "only allows EUR for now" do
    expect { create_subscription(currency: "USD") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows Fixed and Variable amount types" do
    expect(create_subscription(amount_type: "fixed")).to be_valid
    expect(create_subscription(amount_type: "variable")).to be_valid
  end

  it "allows Monthly and Yearly billing cycles" do
    expect(create_subscription(billing_cycle: "monthly")).to be_valid
    expect(create_subscription(billing_cycle: "yearly")).to be_valid
  end

  it "rejects a rating outside 1-5" do
    subscription = create_subscription
    subscription.rating = 6

    expect(subscription).not_to be_valid
  end

  it "does not require a service directory entry or household" do
    subscription = create_subscription

    expect(subscription.service_directory_entry).to be_nil
    expect(subscription.household).to be_nil
  end
end
