class OnboardingController < AuthenticatedController
  def show
    render inertia: "onboarding/show", props: {
      service_directory_entries: ServiceDirectoryEntry.includes(:default_category).order(:name).map do |entry|
        entry.as_json(only: [ :id, :name, :icon_asset, :brand_color, :default_category_id ])
          .merge("default_category_name" => entry.default_category.name)
      end
    }
  end

  # Creates one subscription per checklist item the user filled in an
  # amount + billing date for (PRD 3.1) — anything left incomplete is
  # silently skipped rather than blocking the rest, since onboarding is
  # explicitly meant to be low-friction.
  def create
    created = selections_params.filter_map do |selection|
      next if selection[:amount].blank? || selection[:billing_anchor_date].blank?

      entry = ServiceDirectoryEntry.find_by(id: selection[:service_directory_entry_id])
      next unless entry

      subscription = current_user.subscriptions.create!(
        name: entry.name,
        service_directory_entry: entry,
        category_id: entry.default_category_id,
        currency: "EUR",
        billing_cycle: selection[:billing_cycle].presence || "monthly",
        amount_type: "fixed",
        billing_anchor_date: selection[:billing_anchor_date]
      )
      subscription.confirm_amount!(selection[:amount])
      subscription
    end

    current_user.update!(onboarded_at: Time.current)
    redirect_to subscriptions_path, notice: completion_notice(created.size), status: :see_other
  end

  # Skipping still leads into the standard quick-add flow (PRD 3.1), it just
  # skips the checklist step itself.
  def skip
    current_user.update!(onboarded_at: Time.current)
    redirect_to new_subscription_path, status: :see_other
  end

  private

  def selections_params
    Array(params[:selections]).filter_map do |selection|
      next unless selection.respond_to?(:permit)

      selection.permit(:service_directory_entry_id, :amount, :billing_anchor_date, :billing_cycle)
    end
  end

  def completion_notice(count)
    return "Welcome to Renewly!" if count.zero?

    "Welcome to Renewly! Added #{count} subscription#{'s' unless count == 1}."
  end
end
