require "test_helper"

class Api::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @user = users(:customer)
    @product = products(:lamp)
  end

  test "POST /api/orders creates order for authenticated user" do
    sign_in_as(@user)

    # Add to cart via API
    post api_cart_items_url, params: { product_id: @product.id, quantity: 1 }
    assert_response :success

    post api_orders_url
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "success", json["status"]
    assert_equal 8800, json["order"]["total_amount"]
  end
end
