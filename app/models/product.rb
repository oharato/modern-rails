class Product < ApplicationRecord
  belongs_to :category
  has_many :product_images, dependent: :destroy
  has_many_attached :images
  has_many :order_items, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(is_published: true) }
  scope :featured, -> { published.order(created_at: :desc).limit(4) }
  scope :recent, -> { published.order(created_at: :desc).limit(8) }

  after_commit :purge_catalog_cache

  def in_stock?
    stock_quantity > 0
  end

  def stock_status
    if stock_quantity <= 0
      "out_of_stock"
    elsif stock_quantity <= 3
      "low_stock"
    else
      "in_stock"
    end
  end

  def average_rating
    reviews.average(:rating)&.round(1) || 0.0
  end

  def rating_count
    reviews.count
  end

  def primary_image
    images.attached? ? images.first : nil
  end

  def purge_catalog_cache
    Rails.cache.delete("catalog_top")
    Rails.cache.delete("catalog_products_all")
    Rails.cache.delete("catalog_categories_all")
    Rails.cache.delete("product_detail_#{slug}")
  end
end
