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
class Category < ApplicationRecord
  belongs_to :user, optional: true
  has_many :subscriptions
  has_many :one_time_expenses

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  scope :presets, -> { where(is_preset: true) }
  scope :visible_to, ->(user) { where(is_preset: true).or(where(user_id: user.id)) }

  # The fallback preset custom categories get reassigned to on delete (see
  # CategoriesController#destroy) — always present, seeded in db/seeds.rb.
  def self.other_preset
    presets.find_by!(name: "Other")
  end
end
