require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:lamp)
  end

  test "should get index" do
    get products_url
    assert_response :success
    assert_select "h1", "すべての商品"
  end

  test "should get show" do
    get product_url(@product.slug)
    assert_response :success
    assert_select "h1", @product.name
  end
end
