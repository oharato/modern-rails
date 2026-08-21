require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Test Category", slug: "test-cat")
    @product = Product.create!(
      category: @category,
      name: "Test Product",
      slug: "test-prod",
      price: 1500,
      stock_quantity: 5
    )
  end

  test "stock_status returns in_stock, low_stock, and out_of_stock correctly" do
    assert_equal "in_stock", @product.stock_status

    @product.stock_quantity = 2
    assert_equal "low_stock", @product.stock_status

    @product.stock_quantity = 0
    assert_equal "out_of_stock", @product.stock_status
  end

  test "average_rating calculation" do
    user = User.create!(email_address: "reviewer@example.com", password: "password123")
    assert_equal 0.0, @product.average_rating

    @product.reviews.create!(user: user, rating: 4, comment: "Good")
    @product.reviews.create!(user: user, rating: 5, comment: "Great")

    assert_equal 4.5, @product.average_rating
    assert_equal 2, @product.rating_count
  end
end
