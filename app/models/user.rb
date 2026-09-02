# == Schema Information
#
# Table name: users
#
#  id                         :uuid             not null, primary key
#  confirmation_sent_at       :datetime
#  confirmation_token         :string
#  confirmed_at               :datetime
#  default_reminder_lead_days :integer          default(3), not null
#  email                      :string           default(""), not null
#  encrypted_password         :string           default(""), not null
#  home_currency              :string           default("EUR"), not null
#  is_premium                 :boolean          default(FALSE), not null
#  premium_since              :datetime
#  provider                   :string
#  remember_created_at        :datetime
#  reset_password_sent_at     :datetime
#  reset_password_token       :string
#  uid                        :string
#  unconfirmed_email          :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  before_create :skip_confirmation!

  has_many :categories, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :one_time_expenses, dependent: :destroy
  has_one :household_member, dependent: :destroy
  has_one :household, through: :household_member
  has_one :owned_household, class_name: "Household", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create! do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.confirmed_at = Time.current
    end
  end
end
