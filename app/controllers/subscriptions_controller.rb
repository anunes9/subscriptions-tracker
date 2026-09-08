class SubscriptionsController < AuthenticatedController
  before_action :set_subscription, only: [ :show, :edit, :update, :destroy, :duplicate ]

  def index
    subscriptions = current_user.subscriptions.includes(:category, :service_directory_entry, :history_log_entries).order(:name)

    render inertia: "subscriptions/index", props: {
      subscriptions: subscriptions.map { |subscription| serialize(subscription) }
    }
  end

  def new
    render inertia: "subscriptions/new", props: form_props
  end

  def create
    subscription = current_user.subscriptions.new(subscription_params)
    amount = params.dig(:subscription, :amount)

    subscription.valid?
    subscription.errors.add(:amount, "can't be blank") if amount.blank?

    if subscription.errors.empty? && subscription.save
      subscription.confirm_amount!(amount)
      redirect_to subscriptions_path, notice: "Subscription added.", status: :see_other
    else
      render inertia: "subscriptions/new", props: form_props.merge(errors: subscription.errors.to_hash(true))
    end
  end

  def show
    render inertia: "subscriptions/show", props: { subscription: serialize(@subscription, detailed: true) }
  end

  def edit
    render inertia: "subscriptions/edit", props: form_props.merge(subscription: serialize(@subscription))
  end

  def update
    amount = params.dig(:subscription, :amount)
    new_amount_type = subscription_params[:amount_type]

    # Lock in the current period under the *old* amount_type before it
    # changes, so switching Fixed<->Variable never loses/backdates history
    # (PRD 4.1.1: "past periods already in the log stay as-is").
    if new_amount_type.present? && new_amount_type != @subscription.amount_type
      @subscription.ensure_current_period_logged!
    end

    if @subscription.update(subscription_params)
      @subscription.confirm_amount!(amount) if amount.present?
      redirect_to subscriptions_path, notice: "Subscription updated.", status: :see_other
    else
      render inertia: "subscriptions/edit", props: form_props.merge(
        subscription: serialize(@subscription),
        errors: @subscription.errors.to_hash(true)
      )
    end
  end

  def destroy
    @subscription.destroy!
    redirect_to subscriptions_path, notice: "Subscription deleted.", status: :see_other
  end

  def duplicate
    copy = @subscription.dup
    copy.name = "#{@subscription.name} (copy)"
    copy.status = "active"
    copy.save!

    redirect_to subscriptions_path, notice: "Subscription duplicated.", status: :see_other
  end

  private

  def set_subscription
    @subscription = current_user.subscriptions.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(
      :name, :billing_cycle, :billing_anchor_date, :category_id, :service_directory_entry_id,
      :icon_override, :color_override, :notes, :status, :amount_type, :subscription_type,
      :trial_end_date, :rating, :tag
    )
  end

  def form_props
    {
      categories: Category.visible_to(current_user).order(:is_preset, :name).map do |category|
        category.as_json(only: [ :id, :name, :icon, :color, :is_preset ])
      end
    }
  end

  def serialize(subscription, detailed: false)
    json = subscription.as_json(only: [
      :id, :name, :currency, :billing_cycle, :amount_type, :subscription_type, :status,
      :billing_anchor_date, :trial_end_date, :rating, :tag, :icon_override, :color_override,
      :notes, :category_id, :service_directory_entry_id
    ])
    current_entry = subscription.ensure_current_period_logged!
    json["current_amount"] = current_entry&.amount
    json["current_amount_estimated"] = current_entry&.is_estimated || false
    json["monthly_equivalent_amount"] = subscription.monthly_equivalent(current_entry&.amount)
    json["category"] = subscription.category.as_json(only: [ :id, :name, :color, :icon ])

    if detailed
      json["cancellation_url"] = subscription.service_directory_entry&.cancellation_url
    end

    json
  end
end
