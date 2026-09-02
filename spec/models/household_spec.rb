require 'rails_helper'

# == Schema Information
#
# Table name: households
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :uuid             not null
#
# Indexes
#
#  index_households_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
RSpec.describe Household, type: :model do
  it "belongs to an owner" do
    owner = create_user
    household = Household.create!(name: "The Smiths", owner: owner)

    expect(household.owner).to eq(owner)
  end

  it "lists its members through household_members" do
    owner = create_user
    household = Household.create!(name: "The Smiths", owner: owner)
    HouseholdMember.create!(household: household, user: owner, role: :owner, joined_at: Time.current)

    expect(household.members).to eq([ owner ])
  end
end
