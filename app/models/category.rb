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
class Category < ApplicationRecord
  belongs_to :user, optional: true
  has_many :subscriptions
  has_many :one_time_expenses

  validates :name, presence: true
end
