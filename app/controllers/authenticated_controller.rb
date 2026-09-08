class AuthenticatedController < InertiaController
  before_action :authenticate_user!
  before_action :redirect_to_onboarding_if_needed

  private

  # Applies to every authenticated controller except OnboardingController
  # itself (checked by name rather than a skip_before_action in that
  # controller, so a future authenticated controller can't forget to add
  # it) — a brand-new user is sent through the checklist (PRD 3.1) exactly
  # once, regardless of which flow created their account (password sign-up,
  # Google OAuth, or the passwordless magic link all land here the same way).
  def redirect_to_onboarding_if_needed
    return if current_user.onboarded_at.present?
    return if controller_name == "onboarding"

    redirect_to onboarding_path
  end
end
