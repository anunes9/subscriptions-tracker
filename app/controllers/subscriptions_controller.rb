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
      upsert_current_period_amount!(subscription, amount)
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

    if @subscription.update(subscription_params)
      upsert_current_period_amount!(@subscription, amount) if amount.present?
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
    json["current_amount"] = subscription.history_log_entries.max_by(&:period)&.amount
    json["category"] = subscription.category.as_json(only: [ :id, :name, :color, :icon ])

    if detailed
      json["cancellation_url"] = subscription.service_directory_entry&.cancellation_url
    end

    json
  end

  # Records what the user says this period's amount is — the shared log
  # every subscription maintains regardless of Fixed/Variable (PRD 4.1.1).
  # Ticket 1.4 builds the carry-forward-estimate/confirm engine on top of
  # this; add/edit only ever touch the current period's own entry.
  def upsert_current_period_amount!(subscription, amount)
    entry = subscription.history_log_entries.find_or_initialize_by(period: subscription.current_period)
    entry.amount = amount
    entry.currency = subscription.currency
    entry.is_estimated = false
    entry.confirmed_at = Time.current
    entry.save!
  end
end
