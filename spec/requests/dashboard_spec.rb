require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create_user }
  let(:category) { create_category }

  describe "GET /" do
    it "requires authentication" do
      get "/"

      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders for a signed-in, onboarded user" do
      sign_in user

      get "/"

      expect(response).to have_http_status(:ok)
    end

    it "normalizes yearly amounts and sums monthly ones for the headline total" do
      sign_in user
      monthly = create_subscription(user: user, category: category, billing_cycle: "monthly")
      monthly.confirm_amount!(10)
      yearly = create_subscription(user: user, category: category, billing_cycle: "yearly", billing_anchor_date: Date.current)
      yearly.confirm_amount!(120)

      get "/"

      expect(inertia.props[:monthly_total]).to eq("20.0")
    end

    it "excludes paused/cancelled subscriptions from the total" do
      sign_in user
      active = create_subscription(user: user, category: category, status: "active")
      active.confirm_amount!(10)
      paused = create_subscription(user: user, category: category, status: "paused")
      paused.confirm_amount!(999)

      get "/"

      expect(inertia.props[:monthly_total]).to eq("10.0")
    end

    it "counts only this month's actual charges for the actual-this-month total, ignoring yearly subscriptions renewing elsewhere" do
      sign_in user
      monthly = create_subscription(user: user, category: category, billing_cycle: "monthly")
      monthly.confirm_amount!(10)
      yearly_elsewhere = create_subscription(
        user: user, category: category, billing_cycle: "yearly",
        billing_anchor_date: Date.current + 5.months
      )
      yearly_elsewhere.confirm_amount!(120)

      get "/"

      expect(inertia.props[:actual_this_month_total]).to eq("10.0")
    end

    it "lists upcoming renewals within 14 days, sorted, and omits ones further out" do
      sign_in user
      soon = create_subscription(
        user: user, category: category, name: "Soon",
        billing_cycle: "monthly", billing_anchor_date: (Date.current + 3.days)
      )
      soon.confirm_amount!(5)
      far = create_subscription(
        user: user, category: category, name: "Far",
        billing_cycle: "monthly", billing_anchor_date: (Date.current + 20.days)
      )
      far.confirm_amount!(5)

      get "/"

      names = inertia.props[:upcoming_renewals].map { |entry| entry[:name] }
      expect(names).to eq([ "Soon" ])
    end

    it "breaks down the normalized total by category" do
      sign_in user
      streaming = create_category(name: "Streaming & Entertainment")
      music = create_category(name: "Music & Audio")
      create_subscription(user: user, category: streaming).confirm_amount!(10)
      create_subscription(user: user, category: music).confirm_amount!(5)

      get "/"

      breakdown = inertia.props[:category_breakdown].index_by { |entry| entry[:category][:name] }
      expect(breakdown["Streaming & Entertainment"][:monthly_total]).to eq("10.0")
      expect(breakdown["Music & Audio"][:monthly_total]).to eq("5.0")
    end

    it "splits count and cost by billing cycle" do
      sign_in user
      create_subscription(user: user, category: category, billing_cycle: "monthly").confirm_amount!(10)
      create_subscription(user: user, category: category, billing_cycle: "yearly", billing_anchor_date: Date.current).confirm_amount!(120)

      get "/"

      expect(inertia.props[:cycle_split]).to eq(
        "monthly_count" => 1, "yearly_count" => 1, "monthly_cost" => "10.0", "yearly_cost" => "120.0"
      )
    end
  end
end
