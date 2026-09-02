class PasswordlessLoginRequestsController < ApplicationController
  def new
    render inertia: "auth/passwordless"
  end

  def create
    email = params[:email].to_s

    if email.match?(URI::MailTo::EMAIL_REGEXP)
      request_record = PasswordlessLoginRequest.request_for(email)
      PasswordlessLoginMailer.magic_link(
        request_record,
        raw_token: request_record.raw_token,
        raw_code: request_record.raw_code
      ).deliver_later
    end

    # Always respond the same way whether or not the email matched an account/was valid,
    # so the response can't be used to enumerate which emails are registered.
    render inertia: "auth/passwordless", props: { sent_to: email }
  end

  def show
    request_record = PasswordlessLoginRequest.consume_by_token(params[:token])

    if request_record
      sign_in_passwordless(request_record.email)
    else
      redirect_to new_passwordless_login_request_path, alert: "This link is invalid or has expired."
    end
  end

  def verify
    request_record = PasswordlessLoginRequest.consume_by_code(params[:email], params[:code])

    if request_record
      sign_in_passwordless(request_record.email)
    else
      render inertia: "auth/passwordless", props: {
        sent_to: params[:email],
        errors: { code: [ "is invalid or has expired" ] }
      }
    end
  end

  private

  def sign_in_passwordless(email)
    user = User.find_or_create_by!(email: PasswordlessLoginRequest.normalize_email(email)) do |new_user|
      new_user.password = Devise.friendly_token[0, 20]
    end

    sign_in(user)
    # Inertia requires a 303 (rather than the default 302) on redirects following a
    # non-GET request, so the client follows up with a GET instead of repeating the method.
    redirect_to root_path, notice: "Signed in successfully.", status: :see_other
  end
end
