require "test_helper"

class DailySalesReportJobTest < ActiveJob::TestCase
  setup do
    @user = users(:customer)
    @product = products(:lamp)
    @order = @user.orders.create!(
      order_number: "ORD-TEST-REPORT-001",
      total_amount: 8800,
      status: "paid"
    )
    @order.order_items.create!(product: @product, price_at_purchase: 8800, quantity: 1)
  end

  test "aggregates daily sales and records completed JobLog" do
    assert_difference("JobLog.count", 1) do
      DailySalesReportJob.perform_now(Date.current.to_s)
    end

    job_log = JobLog.last
    assert_equal "daily_sales_report", job_log.job_type
    assert_equal "completed", job_log.status
    payload = JSON.parse(job_log.payload)
    assert_equal 1, payload["orders_count"]
    assert_equal 8800, payload["total_sales"]
  end
end
