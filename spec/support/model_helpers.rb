module ModelHelpers
  def create_user(email: "user-#{SecureRandom.hex(4)}@example.com")
    User.create!(email: email, password: "Password123!")
  end

  def create_category(name: "Streaming & Entertainment", **attrs)
    Category.create!(name: name, **attrs)
  end

  # Wrapped in SET LOCAL app.current_user_id, matching what ApplicationController's
  # around_action does for a real request — Row-Level Security (see
  # db/migrate/*_enable_rls_on_subscriptions.rb) otherwise rejects the insert outright.
  def create_subscription(user: create_user, category: create_category, **attrs)
    subscription = nil

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(user.id)}")
      subscription = Subscription.create!(
        {
          user: user,
          category: category,
          name: "Netflix",
          currency: "EUR",
          billing_cycle: "monthly",
          amount_type: "fixed",
          billing_anchor_date: Date.current
        }.merge(attrs)
      )
    end

    subscription
  end
end

RSpec.configure do |config|
  config.include ModelHelpers
end
