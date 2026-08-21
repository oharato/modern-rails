class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_one_attached :receipt

  validates :order_number, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }

  def self.generate_order_number
    "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(4).upcase}"
  end
end
