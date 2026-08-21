class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @cart = current_cart
    @items = @cart.items
  end

  def add_item
    product_id = params[:product_id]
    quantity = (params[:quantity] || 1).to_i

    current_cart.add_item(product_id, quantity)

    respond_to do |format|
      format.html { redirect_back fallback_location: cart_path, notice: "カートに商品を追加しました。" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("cart_nav_badge", partial: "shared/cart_badge"),
          turbo_stream.replace("flash_messages", partial: "shared/flash", locals: { notice: "カートに商品を追加しました。" })
        ]
      end
      format.json { render json: { status: "success", total_count: current_cart.total_count, total_amount: current_cart.total_amount } }
    end
  end

  def update_quantity
    product_id = params[:product_id]
    quantity = params[:quantity].to_i

    current_cart.update_quantity(product_id, quantity)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "カートを更新しました。" }
      format.turbo_stream do
        @cart = current_cart
        @items = @cart.items
        render turbo_stream: [
          turbo_stream.replace("cart_contents", partial: "carts/cart_contents", locals: { cart: @cart, items: @items }),
          turbo_stream.replace("cart_nav_badge", partial: "shared/cart_badge")
        ]
      end
      format.json { render json: { status: "success", total_count: current_cart.total_count, total_amount: current_cart.total_amount } }
    end
  end

  def remove_item
    product_id = params[:product_id]
    current_cart.remove_item(product_id)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "商品をカートから削除しました。" }
      format.turbo_stream do
        @cart = current_cart
        @items = @cart.items
        render turbo_stream: [
          turbo_stream.replace("cart_contents", partial: "carts/cart_contents", locals: { cart: @cart, items: @items }),
          turbo_stream.replace("cart_nav_badge", partial: "shared/cart_badge")
        ]
      end
      format.json { render json: { status: "success", total_count: current_cart.total_count, total_amount: current_cart.total_amount } }
    end
  end

  def clear
    current_cart.clear

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "カートを空にしました。" }
      format.turbo_stream do
        @cart = current_cart
        @items = []
        render turbo_stream: [
          turbo_stream.replace("cart_contents", partial: "carts/cart_contents", locals: { cart: @cart, items: @items }),
          turbo_stream.replace("cart_nav_badge", partial: "shared/cart_badge")
        ]
      end
      format.json { render json: { status: "success" } }
    end
  end
end
