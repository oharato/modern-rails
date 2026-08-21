class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  alias_attribute :email, :email_address

  def admin?
    role == "admin"
  end

  def customer?
    role == "customer"
  end
end
