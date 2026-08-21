class Api::ReviewsController < Api::BaseController
  allow_unauthenticated_access only: %i[index]

  def index
    product = Product.published.find_by!(slug: params[:slug])
    reviews = product.reviews.recent.includes(:user).map do |r|
      {
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        user_name: r.user.name.presence || r.user.email_address.split("@").first,
        created_at: r.created_at.iso8601
      }
    end
    render json: { reviews: reviews }
  end

  def create
    product = Product.published.find_by!(slug: params[:slug])
    review = product.reviews.build(
      rating: params[:rating],
      comment: params[:comment],
      user: current_user
    )

    if review.save
      render json: { status: "success", review: review }, status: :created
    else
      render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
