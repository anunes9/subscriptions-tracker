require 'rails_helper'

# == Schema Information
#
# Table name: passwordless_login_requests
# Database name: primary
#
#  id         :uuid             not null, primary key
#  code_hash  :string           not null
#  email      :string           not null
#  expires_at :datetime         not null
#  token_hash :string           not null
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_passwordless_login_requests_on_email       (email)
#  index_passwordless_login_requests_on_token_hash  (token_hash) UNIQUE
#
RSpec.describe PasswordlessLoginRequest, type: :model do
  describe ".request_for" do
    it "generates a raw token and code, storing only their hashes" do
      request_record = PasswordlessLoginRequest.request_for(" Someone@Example.com ")

      expect(request_record.email).to eq("someone@example.com")
      expect(request_record.raw_token).to be_present
      expect(request_record.raw_code).to match(/\A\d{6}\z/)
      expect(request_record.token_hash).to eq(described_class.digest(request_record.raw_token))
      expect(request_record.code_hash).to eq(described_class.digest(request_record.raw_code))
      expect(request_record.expires_at).to be_within(1.second).of(PasswordlessLoginRequest::EXPIRES_IN.from_now)
    end
  end

  describe ".consume_by_token" do
    it "returns and marks used the matching active request" do
      request_record = PasswordlessLoginRequest.request_for("token-user@example.com")

      consumed = described_class.consume_by_token(request_record.raw_token)

      expect(consumed).to eq(request_record)
      expect(consumed.used_at).to be_present
    end

    it "returns nil for an unknown token" do
      expect(described_class.consume_by_token("not-a-real-token")).to be_nil
    end

    it "returns nil once the request has already been used" do
      request_record = PasswordlessLoginRequest.request_for("reuse-user@example.com")
      described_class.consume_by_token(request_record.raw_token)

      expect(described_class.consume_by_token(request_record.raw_token)).to be_nil
    end

    it "returns nil once the request has expired" do
      request_record = PasswordlessLoginRequest.request_for("expired-user@example.com")
      request_record.update_column(:expires_at, 1.minute.ago)

      expect(described_class.consume_by_token(request_record.raw_token)).to be_nil
    end
  end

  describe ".consume_by_code" do
    it "returns and marks used the matching active request for that email" do
      request_record = PasswordlessLoginRequest.request_for("code-user@example.com")

      consumed = described_class.consume_by_code("code-user@example.com", request_record.raw_code)

      expect(consumed).to eq(request_record)
      expect(consumed.used_at).to be_present
    end

    it "returns nil for a correct code but the wrong email" do
      request_record = PasswordlessLoginRequest.request_for("owner@example.com")

      expect(described_class.consume_by_code("someone-else@example.com", request_record.raw_code)).to be_nil
    end
  end
end
