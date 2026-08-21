require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Rails.cache.clear
    @user = users(:customer)
    @product = products(:lamp)
  end

  test "logged in user can checkout and place order" do
    sign_in_as(@user)

    # Add to cart
    post add_item_cart_url, params: { product_id: @product.id, quantity: 2 }

    assert_difference("Order.count", 1) do
      assert_difference("OrderItem.count", 1) do
        assert_enqueued_jobs 2 do
          post orders_url
        end
      end
    end

    order = Order.last
    assert_redirected_to complete_order_url(order)
    assert_equal "paid", order.status
    assert_equal 17600, order.total_amount # 8800 * 2

    # Verify stock reduction
    assert_equal 3, @product.reload.stock_quantity # 5 - 2 = 3
  end

  test "out of stock fails and rolls back transaction" do
    sign_in_as(@user)

    post add_item_cart_url, params: { product_id: @product.id, quantity: 10 } # stock is only 5

    assert_no_difference("Order.count") do
      post orders_url
    end

    assert_redirected_to checkout_url
    assert_equal 5, @product.reload.stock_quantity # untouched
  end

  test "user can view their order history and download receipt" do
    sign_in_as(@user)

    order = @user.orders.create!(
      order_number: "ORD-TEST-1234",
      total_amount: 8800,
      status: "paid"
    )
    order.order_items.create!(product: @product, price_at_purchase: 8800, quantity: 1)

    get mypage_orders_url
    assert_response :success
    assert_select "span", text: "ORD-TEST-1234"

    get receipt_order_url(order)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end
end
