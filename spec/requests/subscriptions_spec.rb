require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create_user }
  let(:category) { create_category }

  describe "GET /subscriptions" do
    it "requires authentication" do
      get "/subscriptions"

      expect(response).to redirect_to(new_user_session_path)
    end

    it "only lists the current user's own subscriptions" do
      sign_in user
      create_subscription(user: user, category: category, name: "Mine")
      create_subscription(user: create_user, category: create_category, name: "Not mine")

      get "/subscriptions"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /subscriptions" do
    def valid_params(**overrides)
      {
        subscription: {
          name: "Netflix",
          amount: "15.99",
          billing_cycle: "monthly",
          billing_anchor_date: Date.current.to_s,
          category_id: category.id,
          amount_type: "fixed",
          subscription_type: "regular"
        }.merge(overrides)
      }
    end

    it "creates a subscription owned by the current user and logs the first period's amount" do
      sign_in user

      expect {
        post "/subscriptions", params: valid_params
      }.to change(user.subscriptions, :count).by(1)

      expect(response).to redirect_to(subscriptions_path)
      subscription = user.subscriptions.last
      expect(subscription.name).to eq("Netflix")
      entry = subscription.history_log_entries.sole
      expect(entry.period).to eq(subscription.current_period)
      expect(entry.amount).to eq(15.99)
      expect(entry.is_estimated).to be false
      expect(entry.confirmed_at).to be_present
    end

    it "requires an amount even though it isn't a Subscription column" do
      sign_in user

      expect {
        post "/subscriptions", params: valid_params(amount: "")
      }.not_to change(Subscription, :count)

      expect(response).to have_http_status(:ok)
    end

    it "re-renders with model validation errors when invalid" do
      sign_in user

      post "/subscriptions", params: valid_params(name: "")

      expect(response).to have_http_status(:ok)
      expect(Subscription.count).to eq(0)
    end
  end

  describe "GET /subscriptions/:id" do
    it "404s for another user's subscription" do
      sign_in user
      other_subscription = create_subscription(user: create_user, category: create_category)

      get "/subscriptions/#{other_subscription.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /subscriptions/:id" do
    it "updates the subscription and, when an amount is given, the current period's log entry" do
      sign_in user
      subscription = create_subscription(user: user, category: category, name: "Old name")

      patch "/subscriptions/#{subscription.id}", params: { subscription: { name: "New name", amount: "12.00" } }

      expect(response).to redirect_to(subscriptions_path)
      subscription.reload
      expect(subscription.name).to eq("New name")
      expect(subscription.history_log_entries.sole.amount).to eq(12.00)
    end

    it "leaves the history log alone when no amount is given" do
      sign_in user
      subscription = create_subscription(user: user, category: category)

      patch "/subscriptions/#{subscription.id}", params: { subscription: { name: "Renamed" } }

      expect(subscription.reload.history_log_entries).to be_empty
    end

    it "backfills the current period via carry-forward, under the OLD type's confirmation semantics, before switching amount_type" do
      sign_in user
      subscription = create_subscription(user: user, category: category, amount_type: "fixed")
      subscription.history_log_entries.create!(period: "2020-01", amount: 9.99, currency: "EUR", confirmed_at: Time.current)

      patch "/subscriptions/#{subscription.id}", params: { subscription: { amount_type: "variable" } }

      entries = subscription.history_log_entries.order(:period)
      expect(entries.size).to eq(2)
      backfilled = entries.last
      expect(backfilled.period).to eq(subscription.current_period)
      expect(backfilled.amount).to eq(9.99)
      expect(backfilled.is_estimated).to be false
      expect(backfilled.confirmed_at).to be_present
      expect(subscription.reload.amount_type).to eq("variable")
    end
  end

  describe "DELETE /subscriptions/:id" do
    it "deletes the current user's own subscription" do
      sign_in user
      subscription = create_subscription(user: user, category: category)

      delete "/subscriptions/#{subscription.id}"

      expect(response).to redirect_to(subscriptions_path)
      expect(Subscription.exists?(subscription.id)).to be false
    end
  end

  describe "POST /subscriptions/:id/duplicate" do
    it "creates a copy owned by the current user, active, without the original's history" do
      sign_in user
      subscription = create_subscription(user: user, category: category, name: "Netflix", status: "paused")
      subscription.history_log_entries.create!(period: subscription.current_period, amount: 9.99, currency: "EUR")

      expect {
        post "/subscriptions/#{subscription.id}/duplicate"
      }.to change(user.subscriptions, :count).by(1)

      copy = user.subscriptions.find_by!(name: "Netflix (copy)")
      expect(copy.name).to eq("Netflix (copy)")
      expect(copy.status).to eq("active")
      expect(copy.history_log_entries).to be_empty
    end
  end
end
