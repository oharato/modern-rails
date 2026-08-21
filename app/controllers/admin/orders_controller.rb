module Admin
  class OrdersController < BaseController
    def index
      @orders = Order.recent.includes(:user, order_items: :product)
    end

    def show
      @order = Order.find(params[:id])
    end

    def update_status
      @order = Order.find(params[:id])
      if @order.update(status: params[:status])
        redirect_to admin_orders_path, notice: "注文ステータスを「#{@order.status}」に更新しました。"
      else
        redirect_to admin_orders_path, alert: "ステータスの更新に失敗しました。"
      end
    end
  end
end
