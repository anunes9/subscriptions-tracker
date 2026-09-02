# == Schema Information
#
# Table name: service_directory_entries
#
#  id                  :uuid             not null, primary key
#  brand_color         :string
#  cancellation_url    :string
#  icon_asset          :string           not null
#  name                :string           not null
#  region              :string           default("global"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  default_category_id :uuid             not null
#
# Indexes
#
#  index_service_directory_entries_on_default_category_id  (default_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (default_category_id => categories.id)
#
class ServiceDirectoryEntry < ApplicationRecord
  belongs_to :default_category, class_name: "Category"
  has_many :subscriptions

  validates :name, :icon_asset, :region, presence: true
end
