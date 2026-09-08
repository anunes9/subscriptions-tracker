class AuthenticatedController < InertiaController
  before_action :authenticate_user!
end
