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
class Household < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :household_members, dependent: :destroy
  has_many :members, through: :household_members, source: :user
  has_many :subscriptions
  has_many :one_time_expenses

  validates :name, presence: true
end
