require "test_helper"

class PagesSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @customer = users(:customer)
    @product = products(:lamp)
  end

  test "public pages render successfully without errors" do
    get root_url
    assert_response :success

    get products_url
    assert_response :success

    get product_url(@product.slug)
    assert_response :success

    get category_products_url("craft-art")
    assert_response :success

    get cart_url
    assert_response :success

    get login_url
    assert_response :success

    get signup_url
    assert_response :success

    get guide_url
    assert_response :success
  end

  test "admin backoffice pages render successfully for admin" do
    sign_in_as(@admin)

    get admin_root_url
    assert_response :success

    get admin_products_url
    assert_response :success

    get new_admin_product_url
    assert_response :success

    get edit_admin_product_url(@product)
    assert_response :success

    get admin_orders_url
    assert_response :success

    get admin_jobs_url
    assert_response :success

    get admin_cache_management_url
    assert_response :success
  end
end
