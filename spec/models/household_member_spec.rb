require 'rails_helper'

# == Schema Information
#
# Table name: household_members
#
#  id           :uuid             not null, primary key
#  joined_at    :datetime         not null
#  role         :string           default("member"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  household_id :uuid             not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_household_members_on_household_id  (household_id)
#  index_household_members_on_user_id       (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (household_id => households.id)
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe HouseholdMember, type: :model do
  it "defaults to the member role" do
    owner = create_user
    household = Household.create!(name: "The Smiths", owner: owner)
    member = HouseholdMember.new(household: household, user: create_user, joined_at: Time.current)

    expect(member).to be_valid
    expect(member.role).to eq("member")
  end

  it "only allows a user to belong to one household at a time" do
    user = create_user
    household_a = Household.create!(name: "Household A", owner: user)
    household_b = Household.create!(name: "Household B", owner: create_user)
    HouseholdMember.create!(household: household_a, user: user, role: :owner, joined_at: Time.current)

    duplicate = HouseholdMember.new(household: household_b, user: user, joined_at: Time.current)

    expect(duplicate).not_to be_valid
  end
end
