require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates the preset categories and service directory entries, idempotently" do
    expect { run_seeds }.to change(Category, :count).by(9).and change(ServiceDirectoryEntry, :count).by(24)

    expect { run_seeds }.to_not change(Category, :count)
    expect { run_seeds }.to_not change(ServiceDirectoryEntry, :count)

    expect(Category.where(is_preset: true).count).to eq(9)
    expect(ServiceDirectoryEntry.count).to eq(24)
  end

  it "assigns every service directory entry a default category" do
    run_seeds

    expect(ServiceDirectoryEntry.where(default_category_id: nil)).to be_empty
  end
end
