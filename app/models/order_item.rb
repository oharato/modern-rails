class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :price_at_purchase, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  def subtotal
    price_at_purchase * quantity
  end
end
