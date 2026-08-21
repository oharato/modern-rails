require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    @product = products(:lamp)
  end

  test "authenticated user can post review" do
    sign_in_as(@user)

    assert_difference("@product.reviews.count", 1) do
      post product_reviews_url(@product.slug), params: {
        review: { rating: 5, comment: "本当に素晴らしい間接照明です。" }
      }
    end

    assert_redirected_to product_url(@product.slug)
    review = @product.reviews.last
    assert_equal 5, review.rating
    assert_equal @user.id, review.user_id
  end
end
