class User < ApplicationRecord
  has_many :trips, dependent: :destroy
  has_many :access_tokens, dependent: :destroy

  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, length: { maximum: 80 }, allow_blank: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
end
