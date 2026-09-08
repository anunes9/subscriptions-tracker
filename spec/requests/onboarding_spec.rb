require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create_user(onboarded_at: nil) }

  describe "the onboarding redirect" do
    it "sends a brand-new user to onboarding instead of the page they asked for" do
      sign_in user

      get "/subscriptions"

      expect(response).to redirect_to(onboarding_path)
    end

    it "does not redirect an already-onboarded user" do
      sign_in create_user

      get "/subscriptions"

      expect(response).to have_http_status(:ok)
    end

    it "does not redirect the onboarding controller itself into a loop" do
      sign_in user

      get "/onboarding"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /onboarding" do
    it "lists the service directory grouped by category" do
      sign_in user
      category = create_category(name: "Streaming & Entertainment")
      ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix", default_category: category)

      get "/onboarding"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /onboarding" do
    it "creates a subscription per complete selection, skips incomplete ones, and marks the user onboarded" do
      sign_in user
      category = create_category(name: "Streaming & Entertainment")
      netflix = ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix", default_category: category)
      spotify = ServiceDirectoryEntry.create!(name: "Spotify", icon_asset: "spotify", default_category: category)

      post "/onboarding", params: {
        selections: [
          { service_directory_entry_id: netflix.id, amount: "15.99", billing_anchor_date: Date.current.to_s, billing_cycle: "monthly" },
          # Spotify selected but left incomplete (no amount) — should be skipped, not error.
          { service_directory_entry_id: spotify.id, amount: "", billing_anchor_date: "", billing_cycle: "monthly" }
        ]
      }

      expect(response).to redirect_to(subscriptions_path)
      expect(user.subscriptions.count).to eq(1)
      subscription = user.subscriptions.sole
      expect(subscription.name).to eq("Netflix")
      expect(subscription.service_directory_entry).to eq(netflix)
      expect(subscription.category).to eq(category)
      expect(subscription.history_log_entries.sole.amount).to eq(15.99)
      expect(user.reload.onboarded_at).to be_present
    end

    it "marks the user onboarded even with zero selections" do
      sign_in user

      post "/onboarding", params: { selections: [] }

      expect(user.reload.onboarded_at).to be_present
    end
  end

  describe "POST /onboarding/skip" do
    it "marks the user onboarded and sends them to the quick-add flow" do
      sign_in user

      post "/onboarding/skip"

      expect(response).to redirect_to(new_subscription_path)
      expect(user.reload.onboarded_at).to be_present
    end
  end
end
