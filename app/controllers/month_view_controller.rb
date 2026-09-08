class MonthViewController < AuthenticatedController
  def show
    month_start = target_month_start

    entries = current_user.subscriptions.active.includes(:category, :history_log_entries)
      .filter_map { |subscription| build_entry(subscription, month_start) }
      .sort_by { |entry| entry[:renewal_date] }

    render inertia: "month_view/show", props: {
      year: month_start.year,
      month: month_start.month,
      entries: entries,
      prev_month: { year: month_start.prev_month.year, month: month_start.prev_month.month },
      next_month: { year: month_start.next_month.year, month: month_start.next_month.month }
    }
  end

  private

  def target_month_start
    year = params[:year].presence&.to_i || Date.current.year
    month = params[:month].presence&.to_i || Date.current.month
    Date.new(year, month, 1)
  rescue Date::Error, ArgumentError
    Date.current.beginning_of_month
  end

  # Monthly subscriptions renew every month, on the anchor date's
  # day-of-month (clamped to the last day of shorter months — a subscription
  # anchored on the 31st still renews in February). Yearly subscriptions
  # only show up in the one month they actually renew in (PRD 4.2).
  def renewal_date_within(subscription, month_start)
    anchor = subscription.billing_anchor_date
    return nil if subscription.yearly? && anchor.month != month_start.month

    last_day_of_month = Date.new(month_start.year, month_start.month, -1).day
    Date.new(month_start.year, month_start.month, [ anchor.day, last_day_of_month ].min)
  end

  # Deliberately read-only (unlike SubscriptionsController#index, which calls
  # ensure_current_period_logged! for the pages a user actually manages
  # subscriptions from) — browsing past/future months shouldn't have the
  # side effect of writing history log rows for periods nobody has actually
  # reached yet.
  def build_entry(subscription, month_start)
    renewal_date = renewal_date_within(subscription, month_start)
    return nil unless renewal_date

    latest_entry = subscription.latest_history_entry

    {
      id: subscription.id,
      name: subscription.name,
      billing_cycle: subscription.billing_cycle,
      renewal_date: renewal_date.to_s,
      amount: latest_entry&.amount,
      is_estimated: latest_entry&.is_estimated || false,
      category: subscription.category.as_json(only: [ :id, :name, :color ])
    }
  end
end
