module ModelHelpers
  def create_user(email: "user-#{SecureRandom.hex(4)}@example.com")
    User.create!(email: email, password: "Password123!")
  end

  def create_category(name: "Streaming & Entertainment", **attrs)
    Category.create!(name: name, **attrs)
  end

  def create_subscription(user: create_user, category: create_category, **attrs)
    Subscription.create!(
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
end

RSpec.configure do |config|
  config.include ModelHelpers
end
