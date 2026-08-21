class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @category_slug = params[:category] || params[:slug]
    @query = params[:query]

    cache_key = "catalog_products_#{@category_slug}_#{@query}"
    @products = Rails.cache.fetch(cache_key, expires_in: 60.seconds) do
      scope = Product.published.includes(:category).order(created_at: :desc)
      if @category_slug.present?
        scope = scope.joins(:category).where(categories: { slug: @category_slug })
      end
      if @query.present?
        scope = scope.where("products.name LIKE ? OR products.description LIKE ?", "%#{@query}%", "%#{@query}%")
      end
      scope.to_a
    end

    @categories = Rails.cache.fetch("catalog_categories_all", expires_in: 60.seconds) do
      Category.all.to_a
    end
    @current_category = Category.find_by(slug: @category_slug) if @category_slug.present?
  end

  def show
    @product = Product.published.includes(:category).find_by!(slug: params[:slug])
    @reviews = @product.reviews.recent.includes(:user)
    @new_review = Review.new

    # Track recently viewed in KV store
    current_recently_viewed.record(@product.id)
    @recently_viewed_products = current_recently_viewed.products.reject { |p| p.id == @product.id }
  end
end
