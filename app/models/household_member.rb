# == Schema Information
#
# Table name: household_members
# Database name: primary
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
class HouseholdMember < ApplicationRecord
  belongs_to :household
  belongs_to :user

  enum :role, { member: "member", owner: "owner" }, default: :member

  validates :user_id, uniqueness: true
  validates :joined_at, presence: true
end
