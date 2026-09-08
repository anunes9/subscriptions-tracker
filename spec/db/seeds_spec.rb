require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the preset categories and service directory entries, idempotently" do
    expect { run_seeds }.to change(Category, :count).by(10).and change(ServiceDirectoryEntry, :count).by(53)

    expect { run_seeds }.to_not change(Category, :count)
    expect { run_seeds }.to_not change(ServiceDirectoryEntry, :count)

    expect(Category.where(is_preset: true).count).to eq(10)
    expect(ServiceDirectoryEntry.count).to eq(53)
  end

  it "drops stale presets/directory entries from an earlier seed pass, reassigning dependents to Other" do
    run_seeds
    stale_category = create_category(name: "A Stale Preset", is_preset: true, user: nil)
    subscription = create_subscription(category: stale_category)
    stale_entry = ServiceDirectoryEntry.create!(name: "A Stale Entry", icon_asset: "x", default_category: Category.other_preset)

    run_seeds

    expect(Category.exists?(stale_category.id)).to be false
    expect(subscription.reload.category).to eq(Category.other_preset)
    expect(ServiceDirectoryEntry.exists?(stale_entry.id)).to be false
  end

  it "assigns every service directory entry a default category" do
    run_seeds

    expect(ServiceDirectoryEntry.where(default_category_id: nil)).to be_empty
  end
end
