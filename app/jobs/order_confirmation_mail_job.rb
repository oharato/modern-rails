class OrderConfirmationMailJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    job_log = JobLog.create!(
      job_type: "order_confirmation_mail",
      status: "running",
      payload: { order_id: order.id, order_number: order.order_number, email: order.user.email_address }.to_json
    )

    begin
      OrderMailer.confirmation_email(order).deliver_now
      Rails.logger.info "[OrderConfirmationMailJob] Sent confirmation email for Order ##{order.order_number} to #{order.user.email_address}"

      job_log.update!(
        status: "completed",
        finished_at: Time.current
      )
    rescue => e
      Rails.logger.error "[OrderConfirmationMailJob] Failed for Order ##{order.order_number}: #{e.message}"
      job_log.update!(
        status: "failed",
        payload: { error: e.message, backtrace: e.backtrace&.first(5) }.to_json,
        finished_at: Time.current
      )
      raise e
    end
  end
end
