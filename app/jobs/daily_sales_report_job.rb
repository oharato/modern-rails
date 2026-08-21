class DailySalesReportJob < ApplicationJob
  queue_as :default

  def perform(target_date = Date.current.to_s)
    date = Date.parse(target_date.to_s) rescue Date.current

    job_log = JobLog.create!(
      job_type: "daily_sales_report",
      status: "running",
      payload: { target_date: date.to_s }.to_json
    )

    begin
      start_time = date.beginning_of_day
      end_time = date.end_of_day

      orders = Order.where(created_at: start_time..end_time, status: %w[paid shipped])
      total_sales = orders.sum(:total_amount)
      orders_count = orders.count

      # Top products
      top_items = OrderItem.joins(:order)
                           .where(orders: { created_at: start_time..end_time, status: %w[paid shipped] })
                           .group(:product_id)
                           .select("product_id, SUM(quantity) as total_qty, SUM(price_at_purchase * quantity) as revenue")
                           .order("revenue DESC")
                           .limit(5)

      top_products = top_items.map do |ti|
        product = Product.find_by(id: ti.product_id)
        {
          product_id: ti.product_id,
          name: product&.name || "Unknown",
          quantity: ti.total_qty,
          revenue: ti.revenue
        }
      end

      summary = {
        target_date: date.to_s,
        orders_count: orders_count,
        total_sales: total_sales,
        top_products: top_products,
        generated_at: Time.current.iso8601
      }

      Rails.logger.info "[DailySalesReportJob] Summary for #{date}: #{orders_count} orders, Total: ¥#{total_sales}"

      job_log.update!(
        status: "completed",
        payload: summary.to_json,
        finished_at: Time.current
      )
    rescue => e
      Rails.logger.error "[DailySalesReportJob] Failed: #{e.message}"
      job_log.update!(
        status: "failed",
        payload: { error: e.message, backtrace: e.backtrace&.first(5) }.to_json,
        finished_at: Time.current
      )
      raise e
    end
  end
end
