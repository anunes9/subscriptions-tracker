require 'rails_helper'

# == Schema Information
#
# Table name: categories
# Database name: primary
#
#  id         :uuid             not null, primary key
#  color      :string
#  icon       :string
#  is_preset  :boolean          default(FALSE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_categories_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Category, type: :model do
  it "requires a name" do
    expect(Category.new(is_preset: true)).not_to be_valid
  end

  it "allows a nil user for global preset categories" do
    category = create_category(name: "Other", is_preset: true, user: nil)

    expect(category).to be_valid
    expect(category.is_preset).to be true
  end

  it "belongs to a user for custom categories" do
    user = create_user
    category = create_category(name: "Custom", user: user, is_preset: false)

    expect(category.user).to eq(user)
  end

  it "disallows duplicate names for the same owner, case-insensitively, but allows the same name for different owners" do
    user = create_user
    create_category(name: "Gym", user: user, is_preset: false)

    expect(Category.new(name: "gym", user: user, is_preset: false)).not_to be_valid
    expect(Category.new(name: "Gym", user: create_user, is_preset: false)).to be_valid
  end

  describe ".visible_to" do
    it "includes presets and only the given user's own custom categories" do
      user = create_user
      preset = create_category(name: "Other", is_preset: true, user: nil)
      own = create_category(name: "Mine", user: user, is_preset: false)
      create_category(name: "Someone else's", user: create_user, is_preset: false)

      expect(Category.visible_to(user)).to contain_exactly(preset, own)
    end
  end

  describe ".other_preset" do
    it "finds the seeded Other preset category" do
      other = create_category(name: "Other", is_preset: true, user: nil)

      expect(Category.other_preset).to eq(other)
    end
  end
end
