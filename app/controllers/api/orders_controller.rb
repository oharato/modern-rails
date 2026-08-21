class Api::OrdersController < Api::BaseController
  def create
    cart = current_cart
    items = cart.items

    if items.empty?
      render json: { error: "Cart is empty" }, status: :unprocessable_entity
      return
    end

    order = nil
    ActiveRecord::Base.transaction do
      total_amount = 0
      items.each do |item|
        product = Product.lock.find(item.product_id)
        if product.stock_quantity < item.quantity
          raise "Insufficient stock for #{product.name}"
        end
        product.stock_quantity -= item.quantity
        product.save!
        total_amount += (item.price_at_add || product.price) * item.quantity
      end

      order = current_user.orders.create!(
        order_number: Order.generate_order_number,
        total_amount: total_amount,
        status: "paid"
      )

      items.each do |item|
        order.order_items.create!(
          product_id: item.product_id,
          price_at_purchase: item.price_at_add || item.product.price,
          quantity: item.quantity
        )
      end

      cart.clear
    end

    OrderConfirmationMailJob.perform_later(order.id)
    ReceiptGenerationJob.perform_later(order.id)

    render json: {
      status: "success",
      order: {
        id: order.id,
        order_number: order.order_number,
        total_amount: order.total_amount,
        status: order.status,
        created_at: order.created_at.iso8601
      }
    }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def my
    orders = current_user.orders.recent.includes(order_items: :product).map do |o|
      {
        id: o.id,
        order_number: o.order_number,
        total_amount: o.total_amount,
        status: o.status,
        created_at: o.created_at.iso8601,
        items: o.order_items.map do |oi|
          {
            product_id: oi.product_id,
            product_name: oi.product&.name,
            quantity: oi.quantity,
            price_at_purchase: oi.price_at_purchase,
            subtotal: oi.subtotal
          }
        end
      }
    end

    render json: { orders: orders }
  end

  def receipt
    order = Order.find(params[:id])
    unless current_user.admin? || order.user_id == current_user.id
      render json: { error: "Forbidden" }, status: :forbidden
      return
    end

    if order.receipt.attached?
      send_data order.receipt.download,
                filename: "receipt_#{order.order_number}.pdf",
                type: "application/pdf",
                disposition: "inline"
    else
      ReceiptGenerationJob.perform_now(order.id)
      order.reload
      if order.receipt.attached?
        send_data order.receipt.download,
                  filename: "receipt_#{order.order_number}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      else
        render json: { error: "Receipt is still generating" }, status: :accepted
      end
    end
  end
end
