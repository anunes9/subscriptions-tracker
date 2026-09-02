require "rails_helper"

RSpec.describe "Passwordless login", type: :request do
  describe "POST /login/passwordless" do
    it "creates exactly one unused, unexpired request and enqueues the email" do
      expect do
        post "/login/passwordless", params: { email: "new-user@example.com" }
      end.to change(PasswordlessLoginRequest, :count).by(1)

      request_record = PasswordlessLoginRequest.last
      expect(request_record.email).to eq("new-user@example.com")
      expect(request_record.used_at).to be_nil
      expect(request_record.expires_at).to be > Time.current
    end

    it "does not create a request for an invalid email, but responds the same way" do
      expect do
        post "/login/passwordless", params: { email: "not-an-email" }
      end.not_to change(PasswordlessLoginRequest, :count)

      expect(response).to have_http_status(:ok)
    end

    it "is rate-limited after repeated requests for the same email" do
      4.times { post "/login/passwordless", params: { email: "throttled@example.com" } }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "GET /login/passwordless/verify" do
    it "signs the user in via the magic link and marks the request used" do
      request_record = PasswordlessLoginRequest.request_for("link-user@example.com")

      get "/login/passwordless/verify", params: { token: request_record.raw_token }

      # Inertia requires a 303 (not the Rails default 302) on redirects following a
      # non-GET request, so the client follows up with a GET instead of repeating the method.
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(request_record.reload.used_at).to be_present
      expect(User.find_by(email: "link-user@example.com")).to be_present
    end

    it "rejects an already-used link" do
      request_record = PasswordlessLoginRequest.request_for("used-user@example.com")
      raw_token = request_record.raw_token
      get "/login/passwordless/verify", params: { token: raw_token }

      get "/login/passwordless/verify", params: { token: raw_token }

      expect(response).to redirect_to(new_passwordless_login_request_path)
    end

    it "rejects an expired link" do
      request_record = PasswordlessLoginRequest.request_for("expired-user@example.com")
      request_record.update_column(:expires_at, 1.minute.ago)

      get "/login/passwordless/verify", params: { token: request_record.raw_token }

      expect(response).to redirect_to(new_passwordless_login_request_path)
    end
  end

  describe "POST /login/passwordless/verify" do
    it "signs the user in via the code" do
      request_record = PasswordlessLoginRequest.request_for("code-user@example.com")

      post "/login/passwordless/verify", params: { email: "code-user@example.com", code: request_record.raw_code }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(root_path)
      expect(request_record.reload.used_at).to be_present
    end

    it "rejects an incorrect code" do
      PasswordlessLoginRequest.request_for("bad-code-user@example.com")

      post "/login/passwordless/verify", params: { email: "bad-code-user@example.com", code: "000000" }

      expect(response).to have_http_status(:ok)
    end
  end
end
