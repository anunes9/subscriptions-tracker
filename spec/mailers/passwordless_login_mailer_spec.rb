require "rails_helper"

RSpec.describe PasswordlessLoginMailer, type: :mailer do
  describe "magic_link" do
    let(:request) { PasswordlessLoginRequest.request_for("someone@example.com") }
    let(:mail) { PasswordlessLoginMailer.magic_link(request, raw_token: request.raw_token, raw_code: request.raw_code) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your Renewly sign-in link")
      expect(mail.to).to eq([ "someone@example.com" ])
    end

    it "renders the magic link and the code" do
      expect(mail.body.encoded).to include(request.raw_token)
      expect(mail.body.encoded).to include(request.raw_code)
    end
  end
end
