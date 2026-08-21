class Api::CartsController < Api::BaseController
  allow_unauthenticated_access

  def show
    cart = current_cart
    items = cart.items.map do |item|
      {
        product_id: item.product_id,
        quantity: item.quantity,
        price_at_add: item.price_at_add,
        subtotal: item.subtotal,
        product: {
          name: item.product&.name,
          slug: item.product&.slug,
          price: item.product&.price,
          stock_quantity: item.product&.stock_quantity
        }
      }
    end

    render json: {
      items: items,
      total_count: cart.total_count,
      total_amount: cart.total_amount
    }
  end

  def add_item
    current_cart.add_item(params[:product_id], params[:quantity] || 1)
    render json: {
      status: "success",
      total_count: current_cart.total_count,
      total_amount: current_cart.total_amount
    }
  end

  def update_quantity
    current_cart.update_quantity(params[:id] || params[:product_id], params[:quantity])
    render json: {
      status: "success",
      total_count: current_cart.total_count,
      total_amount: current_cart.total_amount
    }
  end

  def remove_item
    current_cart.remove_item(params[:id] || params[:product_id])
    render json: {
      status: "success",
      total_count: current_cart.total_count,
      total_amount: current_cart.total_amount
    }
  end
end
