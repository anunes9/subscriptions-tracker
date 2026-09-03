require "rails_helper"

RSpec.describe "Row-Level Security on subscriptions", type: :request do
  let(:owner) { create_user }
  let(:other_user) { create_user }
  let(:category) { create_category }

  let!(:owned_subscription) do
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(owner.id)}")
      create_subscription(user: owner, category: category)
    end
  end

  def visible_subscription_ids
    ActiveRecord::Base.connection.select_values("SELECT id FROM subscriptions")
  end

  describe "the raw Postgres policy" do
    it "hides every subscription when app.current_user_id is unset" do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("RESET app.current_user_id")

        expect(visible_subscription_ids).to be_empty
      end
    end

    it "hides another user's subscription" do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(other_user.id)}")

        expect(visible_subscription_ids).not_to include(owned_subscription.id)
      end
    end

    it "reveals the subscription once app.current_user_id matches its owner" do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(owner.id)}")

        expect(visible_subscription_ids).to include(owned_subscription.id)
      end
    end
  end

  describe "ApplicationController#set_current_user_for_row_level_security" do
    around do |example|
      Rails.application.routes.draw do
        get "/__rls_spike_probe", to: "rls_spike_probe#index"
      end
      example.run
      Rails.application.reload_routes!
    end

    # A throwaway controller, defined only for this spec, that exists solely to
    # prove the around_action wires app.current_user_id through a real HTTP
    # request/response cycle — not just a raw SQL connection in a test.
    before do
      stub_const("RlsSpikeProbeController", Class.new(ApplicationController) do
        def index
          render plain: Subscription.count.to_s
        end
      end)
    end

    it "scopes a signed-in request to that user's own subscriptions" do
      sign_in owner

      get "/__rls_spike_probe"

      expect(response.body).to eq("1")
    end

    it "never leaks another user's subscription to a different signed-in user" do
      sign_in other_user

      get "/__rls_spike_probe"

      expect(response.body).to eq("0")
    end
  end
end
