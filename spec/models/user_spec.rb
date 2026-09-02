require "rails_helper"

# == Schema Information
#
# Table name: users
#
#  id                         :uuid             not null, primary key
#  confirmation_sent_at       :datetime
#  confirmation_token         :string
#  confirmed_at               :datetime
#  default_reminder_lead_days :integer          default(3), not null
#  email                      :string           default(""), not null
#  encrypted_password         :string           default(""), not null
#  home_currency              :string           default("EUR"), not null
#  is_premium                 :boolean          default(FALSE), not null
#  premium_since              :datetime
#  provider                   :string
#  remember_created_at        :datetime
#  reset_password_sent_at     :datetime
#  reset_password_token       :string
#  uid                        :string
#  unconfirmed_email          :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
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
