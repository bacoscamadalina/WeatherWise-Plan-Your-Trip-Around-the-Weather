class AccessToken < ApplicationRecord
  LIFETIME = 30.days

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.issue_for(user, name: "default")
    raw_token = SecureRandom.hex(32)
    token = user.access_tokens.create!(
      token_digest: digest(raw_token),
      name:,
      expires_at: LIFETIME.from_now
    )
    [ token, raw_token ]
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def expired?
    expires_at <= Time.current
  end
end
