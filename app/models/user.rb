class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :projects, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def stats_cache_key
    "user_#{id}_stats"
  end

  def clear_stats_cache
    Rails.cache.delete(stats_cache_key)
  end
end
