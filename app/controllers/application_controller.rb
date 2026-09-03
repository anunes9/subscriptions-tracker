class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  inertia_share flash: -> { flash.to_hash }

  around_action :set_current_user_for_row_level_security

  private

  # Row-Level Security policies (see db/migrate/*_enable_rls_on_subscriptions.rb)
  # read this session variable via current_setting('app.current_user_id') to
  # scope queries to rows the signed-in user owns. SET LOCAL only lives for the
  # current transaction, so the whole request runs inside one.
  def set_current_user_for_row_level_security
    return yield unless user_signed_in?

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        "SET LOCAL app.current_user_id = #{ActiveRecord::Base.connection.quote(current_user.id)}"
      )
      yield
    end
  end
end
