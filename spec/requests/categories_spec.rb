require "rails_helper"

RSpec.describe "Categories", type: :request do
  let(:user) { create_user }

  describe "GET /categories" do
    it "requires authentication" do
      get "/categories"

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns presets and only the current user's own custom categories" do
      sign_in user
      create_category(name: "Other", is_preset: true, user: nil)
      create_category(name: "Mine", user: user, is_preset: false)
      create_category(name: "Someone else's", user: create_user, is_preset: false)

      get "/categories"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /categories" do
    it "creates a custom category owned by the current user" do
      sign_in user

      expect {
        post "/categories", params: { category: { name: "Gym", color: "#ff0000" } }
      }.to change(user.categories, :count).by(1)

      expect(response).to redirect_to(categories_path)
      expect(user.categories.last).to have_attributes(name: "Gym", is_preset: false)
    end

    it "re-renders with errors when invalid" do
      sign_in user

      post "/categories", params: { category: { name: "" } }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /categories/:id" do
    it "updates the current user's own category" do
      sign_in user
      category = create_category(name: "Old name", user: user, is_preset: false)

      patch "/categories/#{category.id}", params: { category: { name: "New name" } }

      expect(response).to redirect_to(categories_path)
      expect(category.reload.name).to eq("New name")
    end

    it "404s for another user's category" do
      sign_in user
      other_category = create_category(name: "Not mine", user: create_user, is_preset: false)

      patch "/categories/#{other_category.id}", params: { category: { name: "Hijacked" } }

      expect(response).to have_http_status(:not_found)
      expect(other_category.reload.name).to eq("Not mine")
    end

    it "404s for a preset category" do
      sign_in user
      preset = create_category(name: "Other", is_preset: true, user: nil)

      patch "/categories/#{preset.id}", params: { category: { name: "Hijacked" } }

      expect(response).to have_http_status(:not_found)
      expect(preset.reload.name).to eq("Other")
    end
  end

  describe "DELETE /categories/:id" do
    it "reassigns the category's subscriptions and one-time expenses to Other, then deletes it" do
      sign_in user
      create_category(name: "Other", is_preset: true, user: nil)
      category = create_category(name: "Doomed", user: user, is_preset: false)
      subscription = create_subscription(user: user, category: category)
      expense = OneTimeExpense.create!(user: user, category: category, amount: 10, expense_date: Date.current)

      delete "/categories/#{category.id}"

      expect(response).to redirect_to(categories_path)
      expect(Category.exists?(category.id)).to be false
      expect(subscription.reload.category).to eq(Category.other_preset)
      expect(expense.reload.category).to eq(Category.other_preset)
    end
  end
end
