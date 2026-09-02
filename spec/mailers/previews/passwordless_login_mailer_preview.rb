# Preview all emails at http://localhost:3000/rails/mailers/passwordless_login_mailer
class PasswordlessLoginMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwordless_login_mailer/magic_link
  def magic_link
    request = PasswordlessLoginRequest.request_for("preview@example.com")
    PasswordlessLoginMailer.magic_link(request, raw_token: request.raw_token, raw_code: request.raw_code)
  end
end
