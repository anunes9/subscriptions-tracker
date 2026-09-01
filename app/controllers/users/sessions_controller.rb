class Users::SessionsController < Devise::SessionsController
  def new
    render inertia: "auth/sign_in"
  end
end
