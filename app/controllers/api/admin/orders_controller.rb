class Api::Admin::OrdersController < Api::BaseController
  before_action :require_admin

  def index
    orders = Order.recent.includes(:user, order_items: :product).map do |o|
      {
        id: o.id,
        order_number: o.order_number,
        user_email: o.user.email_address,
        total_amount: o.total_amount,
        status: o.status,
        created_at: o.created_at.iso8601
      }
    end
    render json: { orders: orders }
  end

  def update_status
    order = Order.find(params[:id])
    if order.update(status: params[:status])
      render json: { status: "success", order: order }
    else
      render json: { errors: order.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
