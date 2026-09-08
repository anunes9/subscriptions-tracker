require 'rails_helper'

# == Schema Information
#
# Table name: service_directory_entries
# Database name: primary
#
#  id                  :uuid             not null, primary key
#  brand_color         :string
#  cancellation_url    :string
#  icon_asset          :string           not null
#  name                :string           not null
#  region              :string           default("global"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  default_category_id :uuid             not null
#
# Indexes
#
#  index_service_directory_entries_on_default_category_id  (default_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (default_category_id => categories.id)
#
RSpec.describe ServiceDirectoryEntry, type: :model do
  it "requires a default category" do
    entry = ServiceDirectoryEntry.new(name: "Netflix", icon_asset: "netflix.svg")

    expect(entry).not_to be_valid
  end

  it "links to its default category" do
    category = create_category(name: "Streaming & Entertainment")
    entry = ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix.svg", default_category: category)

    expect(entry.default_category).to eq(category)
  end

  describe ".search" do
    it "matches case-insensitively on a partial name" do
      category = create_category
      netflix = ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix.svg", default_category: category)
      ServiceDirectoryEntry.create!(name: "Spotify", icon_asset: "spotify.svg", default_category: category)

      expect(ServiceDirectoryEntry.search("net")).to contain_exactly(netflix)
      expect(ServiceDirectoryEntry.search("FLIX")).to contain_exactly(netflix)
    end

    it "returns none for a blank query rather than every entry" do
      ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix.svg", default_category: create_category)

      expect(ServiceDirectoryEntry.search(nil)).to be_empty
      expect(ServiceDirectoryEntry.search("")).to be_empty
    end

    it "escapes SQL LIKE wildcards in the query" do
      category = create_category
      ServiceDirectoryEntry.create!(name: "Netflix", icon_asset: "netflix.svg", default_category: category)

      expect(ServiceDirectoryEntry.search("%")).to be_empty
    end
  end
end
