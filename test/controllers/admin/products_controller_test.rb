require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @category = categories(:craft)
    @product = products(:lamp)
  end

  test "admin can view products list" do
    sign_in_as(@admin)
    get admin_products_url
    assert_response :success
    assert_select "div", text: @product.name
  end

  test "admin can update product stock" do
    sign_in_as(@admin)
    patch update_stock_admin_product_url(@product), params: { stock_quantity: 20 }
    assert_redirected_to admin_products_url
    assert_equal 20, @product.reload.stock_quantity
  end

  test "admin can toggle publish state" do
    sign_in_as(@admin)
    assert @product.is_published?
    patch toggle_publish_admin_product_url(@product)
    assert_redirected_to admin_products_url
    assert_not @product.reload.is_published?
  end
end
