require "rails_helper"

RSpec.describe User, type: :model do
  describe "defaults" do
    it "applies the app-specific column defaults from the data model" do
      user = User.create!(email: "defaults@example.com", password: "Password123!")

      expect(user.home_currency).to eq("EUR")
      expect(user.default_reminder_lead_days).to eq(3)
      expect(user.is_premium).to eq(false)
    end

    it "confirms the user immediately, without requiring an email confirmation step" do
      user = User.create!(email: "defaults@example.com", password: "Password123!")

      expect(user).to be_confirmed
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "123545",
        info: { email: "oauth-user@example.com" }
      )
    end

    it "creates a confirmed user on first sign-in" do
      user = User.from_omniauth(auth)

      expect(user).to be_persisted
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("123545")
      expect(user).to be_confirmed
    end

    it "finds the existing user on subsequent sign-ins instead of creating a duplicate" do
      first_user = User.from_omniauth(auth)

      expect { User.from_omniauth(auth) }.not_to change(User, :count)
      expect(User.from_omniauth(auth)).to eq(first_user)
    end
  end
end
