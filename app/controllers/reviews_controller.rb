class ReviewsController < ApplicationController
  def create
    @product = Product.published.find_by!(slug: params[:product_slug])
    @review = @product.reviews.build(review_params.merge(user: current_user))

    respond_to do |format|
      if @review.save
        format.html { redirect_to product_path(@product.slug), notice: "レビューを投稿しました。" }
        format.turbo_stream
        format.json { render json: { status: "success", review: @review }, status: :created }
      else
        format.html { redirect_to product_path(@product.slug), alert: "レビューの投稿に失敗しました: #{@review.errors.full_messages.join(', ')}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("review_form", partial: "reviews/form", locals: { product: @product, review: @review }) }
        format.json { render json: { errors: @review.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
