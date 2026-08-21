require "test_helper"

class ReceiptGenerationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:customer)
    @product = products(:lamp)
    @order = @user.orders.create!(
      order_number: "ORD-TEST-JOB-001",
      total_amount: 8800,
      status: "paid"
    )
    @order.order_items.create!(product: @product, price_at_purchase: 8800, quantity: 1)
  end

  test "generates and attaches receipt PDF and records JobLog" do
    assert_not @order.receipt.attached?

    assert_difference("JobLog.count", 1) do
      ReceiptGenerationJob.perform_now(@order.id)
    end

    @order.reload
    assert @order.receipt.attached?
    assert_equal "application/pdf", @order.receipt.blob.content_type

    job_log = JobLog.last
    assert_equal "receipt_generation", job_log.job_type
    assert_equal "completed", job_log.status
  end
end
