class DashboardController < ApplicationController
  def index
    @recent_orders = Current.user.orders.recent.limit(5).includes(order_items: :product)
    @total_orders_count = Current.user.orders.count
    @total_spent = Current.user.orders.where(status: %w[paid shipped]).sum(:total_amount)
    @reviews_count = Current.user.reviews.count
    @cart = current_cart
    @recently_viewed_products = current_recently_viewed.products
  end
end
