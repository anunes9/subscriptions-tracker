# == Schema Information
#
# Table name: one_time_expenses
# Database name: primary
#
#  id           :uuid             not null, primary key
#  amount       :decimal(12, 2)   not null
#  currency     :string           default("EUR"), not null
#  expense_date :date             not null
#  note         :text
#  visibility   :string           default("shared"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  category_id  :uuid             not null
#  household_id :uuid
#  user_id      :uuid             not null
#
# Indexes
#
#  index_one_time_expenses_on_category_id   (category_id)
#  index_one_time_expenses_on_household_id  (household_id)
#  index_one_time_expenses_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (household_id => households.id)
#  fk_rails_...  (user_id => users.id)
#
class OneTimeExpense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :household, optional: true

  enum :visibility, { private_visibility: "private", shared: "shared" }, default: :shared

  validates :amount, presence: true
  validates :expense_date, presence: true
  # EUR-only for now; USD/multi-currency support is deferred.
  validates :currency, inclusion: { in: %w[EUR] }
end
