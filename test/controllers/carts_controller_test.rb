require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @product = products(:lamp)
  end

  test "guest can add item to cart and view cart" do
    post add_item_cart_url, params: { product_id: @product.id, quantity: 2 }
    assert_redirected_to cart_url

    get cart_url
    assert_response :success
    assert_select "h1", "ショッピングカート"
    assert_select "a", text: @product.name
  end

  test "can update quantity in cart" do
    post add_item_cart_url, params: { product_id: @product.id, quantity: 1 }

    patch update_item_cart_url(@product.id), params: { quantity: 4 }
    assert_redirected_to cart_url

    get cart_url
    assert_response :success
    assert_select "span", text: "4"
  end

  test "can clear cart" do
    post add_item_cart_url, params: { product_id: @product.id, quantity: 1 }

    delete clear_cart_url
    assert_redirected_to cart_url

    get cart_url
    assert_response :success
    assert_select "h2", "カートに商品が入っていません"
  end
end
