require "rails_helper"

RSpec.describe "Service directory entries", type: :request do
  let(:user) { create_user }

  describe "GET /service_directory_entries" do
    it "requires authentication" do
      get "/service_directory_entries", params: { q: "net" }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns matching entries as JSON" do
      sign_in user
      category = create_category
      ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix", default_category: category)
      ServiceDirectoryEntry.create!(name: "Spotify", icon_asset: "spotify", default_category: category)

      get "/service_directory_entries", params: { q: "net" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |entry| entry["name"] }).to eq([ "Netflix" ])
    end

    it "returns an empty array without a query" do
      sign_in user
      ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix", default_category: create_category)

      get "/service_directory_entries"

      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
