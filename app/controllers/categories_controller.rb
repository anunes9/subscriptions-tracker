class CategoriesController < AuthenticatedController
  before_action :set_category, only: [ :update, :destroy ]

  def index
    render inertia: "settings/categories", props: { categories: categories_prop }
  end

  def create
    category = current_user.categories.new(category_params)

    if category.save
      redirect_to categories_path, notice: "Category created.", status: :see_other
    else
      render inertia: "settings/categories", props: {
        categories: categories_prop,
        errors: category.errors.to_hash(true)
      }
    end
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated.", status: :see_other
    else
      render inertia: "settings/categories", props: {
        categories: categories_prop,
        errors: @category.errors.to_hash(true)
      }
    end
  end

  def destroy
    other = Category.other_preset

    ActiveRecord::Base.transaction do
      @category.subscriptions.update_all(category_id: other.id)
      @category.one_time_expenses.update_all(category_id: other.id)
      @category.destroy!
    end

    redirect_to categories_path, notice: "Category deleted. Its subscriptions moved to Other.", status: :see_other
  end

  private

  def set_category
    # Scoped to the user's own custom categories — presets (user_id nil)
    # are never editable/deletable, and this 404s rather than exposing
    # another user's category.
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color)
  end

  def categories_prop
    Category.visible_to(current_user).order(:is_preset, :name).map do |category|
      category.as_json(only: [ :id, :name, :icon, :color, :is_preset ])
    end
  end
end
