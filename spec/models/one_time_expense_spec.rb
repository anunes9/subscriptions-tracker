require 'rails_helper'

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
RSpec.describe OneTimeExpense, type: :model do
  it "defaults visibility to shared, currency to EUR, and does not require a household" do
    expense = OneTimeExpense.create!(user: create_user, category: create_category, amount: 42.5, expense_date: Date.current)

    expect(expense.visibility).to eq("shared")
    expect(expense.currency).to eq("EUR")
    expect(expense.household).to be_nil
  end

  it "only allows EUR for now" do
    attrs = { user: create_user, category: create_category, amount: 10, expense_date: Date.current }

    expect(OneTimeExpense.new(attrs.merge(currency: "EUR"))).to be_valid
    expect(OneTimeExpense.new(attrs.merge(currency: "USD"))).not_to be_valid
  end
end
