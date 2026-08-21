require "test_helper"

class Api::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:lamp)
  end

  test "GET /api/products returns json list of products" do
    get api_products_url
    assert_response :success
    json = JSON.parse(response.body)
    assert json["products"].any? { |p| p["slug"] == @product.slug }
  end

  test "GET /api/products/:slug returns product detail" do
    get api_products_url + "/#{@product.slug}"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @product.name, json["product"]["name"]
  end

  test "GET /api/categories returns category list" do
    get api_categories_url
    assert_response :success
    json = JSON.parse(response.body)
    assert json["categories"].any? { |c| c["slug"] == "craft-art" }
  end
end
