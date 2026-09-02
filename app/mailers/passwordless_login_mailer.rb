class PasswordlessLoginMailer < ApplicationMailer
  def magic_link(passwordless_login_request, raw_token:, raw_code:)
    @code = raw_code
    @magic_link_url = verify_passwordless_login_request_url(token: raw_token)

    mail to: passwordless_login_request.email, subject: "Your Renewly sign-in link"
  end
end
