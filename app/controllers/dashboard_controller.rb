class DashboardController < AuthenticatedController
  UPCOMING_RENEWALS_WINDOW_DAYS = 14

  def show
    subscriptions = current_user.subscriptions.active.includes(:category, :history_log_entries).to_a
    amounts = subscriptions.index_with { |subscription| subscription.latest_history_entry&.amount }

    render inertia: "dashboard/show", props: {
      monthly_total: monthly_total(subscriptions, amounts),
      actual_this_month_total: actual_this_month_total(subscriptions, amounts),
      upcoming_renewals: upcoming_renewals(subscriptions, amounts),
      category_breakdown: category_breakdown(subscriptions, amounts),
      cycle_split: cycle_split(subscriptions, amounts)
    }
  end

  private

  # PRD 4.3's default "monthly view" total: every active subscription
  # normalized to its monthly-equivalent cost (yearly / 12), regardless of
  # what renews this specific calendar month.
  def monthly_total(subscriptions, amounts)
    subscriptions.sum { |subscription| subscription.monthly_equivalent(amounts[subscription]) || 0 }
  end

  # PRD 4.3's alternate "this month's actual charges" total: only what
  # actually renews within the selected (here, current) month, at its real
  # amount — a yearly subscription outside this month contributes nothing.
  def actual_this_month_total(subscriptions, amounts)
    month = Date.current.month

    subscriptions.sum do |subscription|
      next 0 if subscription.yearly? && subscription.billing_anchor_date.month != month

      amounts[subscription] || 0
    end
  end

  def upcoming_renewals(subscriptions, amounts)
    today = Date.current
    cutoff = today + UPCOMING_RENEWALS_WINDOW_DAYS.days

    subscriptions.filter_map do |subscription|
      renewal_date = subscription.next_renewal_date(from: today)
      next if renewal_date > cutoff

      {
        id: subscription.id,
        name: subscription.name,
        renewal_date: renewal_date.to_s,
        amount: amounts[subscription]
      }
    end.sort_by { |entry| entry[:renewal_date] }
  end

  # PRD 4.11 Basic: category breakdown, using the same monthly-equivalent
  # normalization as the headline total so the parts sum to the whole.
  def category_breakdown(subscriptions, amounts)
    subscriptions.group_by(&:category)
      .transform_values { |group| group.sum { |subscription| subscription.monthly_equivalent(amounts[subscription]) || 0 } }
      .sort_by { |_, total| -total }
      .map { |category, total| { category: category.as_json(only: [ :id, :name, :color ]), monthly_total: total } }
  end

  # PRD 4.11 Basic: monthly vs. yearly split, by count and cost.
  def cycle_split(subscriptions, amounts)
    {
      monthly_count: subscriptions.count(&:monthly?),
      yearly_count: subscriptions.count(&:yearly?),
      monthly_cost: subscriptions.sum { |s| s.monthly? ? (amounts[s] || 0) : 0 },
      yearly_cost: subscriptions.sum { |s| s.yearly? ? (amounts[s] || 0) : 0 }
    }
  end
end
