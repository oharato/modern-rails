class CheckoutsController < ApplicationController
  def show
    @cart = current_cart
    if @cart.empty?
      redirect_to cart_path, alert: "カートに商品がありません。"
      return
    end

    @items = @cart.items
    @total_amount = @cart.total_amount
  end
end
