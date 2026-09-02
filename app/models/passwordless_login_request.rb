# == Schema Information
#
# Table name: passwordless_login_requests
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
class PasswordlessLoginRequest < ApplicationRecord
  EXPIRES_IN = 10.minutes

  attr_reader :raw_token, :raw_code

  validates :email, presence: true
  validates :token_hash, :code_hash, :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  before_validation :assign_token_and_code, on: :create
  before_validation :assign_expiration, on: :create

  def self.request_for(email)
    create!(email: normalize_email(email))
  end

  def self.consume_by_token(raw_token)
    return nil if raw_token.blank?

    consume(active.find_by(token_hash: digest(raw_token)))
  end

  def self.consume_by_code(email, raw_code)
    return nil if email.blank? || raw_code.blank?

    consume(active.find_by(email: normalize_email(email), code_hash: digest(raw_code)))
  end

  def self.digest(value)
    Digest::SHA256.hexdigest(value.to_s)
  end

  def self.normalize_email(email)
    email.to_s.downcase.strip
  end

  def self.consume(request)
    return nil unless request

    request.update!(used_at: Time.current)
    request
  end
  private_class_method :consume

  private

  def assign_token_and_code
    @raw_token = SecureRandom.urlsafe_base64(32)
    @raw_code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
    self.token_hash = self.class.digest(@raw_token)
    self.code_hash = self.class.digest(@raw_code)
  end

  def assign_expiration
    self.expires_at ||= EXPIRES_IN.from_now
  end
end
