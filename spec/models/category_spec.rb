require 'rails_helper'

# == Schema Information
#
# Table name: categories
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
end
