module Admin
  class DashboardController < BaseController
    def index
      @total_sales = Order.where(status: %w[paid shipped]).sum(:total_amount)
      @total_orders_count = Order.where(status: %w[paid shipped]).count
      @today_sales = Order.where(created_at: Date.current.all_day, status: %w[paid shipped]).sum(:total_amount)
      @today_orders_count = Order.where(created_at: Date.current.all_day, status: %w[paid shipped]).count
      @recent_orders = Order.recent.limit(10).includes(:user, order_items: :product)
      @recent_job_logs = JobLog.recent.limit(5)
    end
  end
end
