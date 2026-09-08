require "rails_helper"

RSpec.describe "Month view", type: :request do
  let(:user) { create_user }
  let(:category) { create_category }

  describe "GET /month_view" do
    it "requires authentication" do
      get "/month_view"

      expect(response).to redirect_to(new_user_session_path)
    end

    it "defaults to the current month" do
      sign_in user

      get "/month_view"

      expect(response).to have_http_status(:ok)
      expect(inertia.props[:year]).to eq(Date.current.year)
      expect(inertia.props[:month]).to eq(Date.current.month)
    end

    it "includes a monthly subscription every month, clamped to the last day of shorter months" do
      sign_in user
      create_subscription(user: user, category: category, billing_cycle: "monthly", billing_anchor_date: Date.new(2026, 1, 31))

      get "/month_view", params: { year: 2026, month: 2 }

      expect(inertia.props[:entries].sole[:renewal_date]).to eq("2026-02-28")
    end

    it "only includes a yearly subscription in the month it actually renews" do
      sign_in user
      create_subscription(user: user, category: category, billing_cycle: "yearly", billing_anchor_date: Date.new(2020, 3, 15))

      get "/month_view", params: { year: 2026, month: 3 }
      expect(inertia.props[:entries].sole[:renewal_date]).to eq("2026-03-15")

      get "/month_view", params: { year: 2026, month: 4 }
      expect(inertia.props[:entries]).to be_empty
    end

    it "excludes paused and cancelled subscriptions" do
      sign_in user
      create_subscription(user: user, category: category, status: "paused")
      create_subscription(user: user, category: category, status: "cancelled")

      get "/month_view"

      expect(inertia.props[:entries]).to be_empty
    end

    it "shows the latest logged amount without creating new history log rows" do
      sign_in user
      subscription = create_subscription(user: user, category: category)
      subscription.history_log_entries.create!(period: "2020-01", amount: 9.99, currency: "EUR", confirmed_at: Time.current)

      expect {
        get "/month_view"
      }.not_to change(HistoryLogEntry, :count)

      entry = inertia.props[:entries].sole
      expect(entry[:amount]).to eq("9.99")
    end

    it "computes prev/next month, wrapping across year boundaries" do
      sign_in user

      get "/month_view", params: { year: 2026, month: 1 }

      expect(inertia.props[:prev_month]).to eq("year" => 2025, "month" => 12)
      expect(inertia.props[:next_month]).to eq("year" => 2026, "month" => 2)
    end
  end
end
