class Api::ProductsController < Api::BaseController
  allow_unauthenticated_access

  def index
    category_slug = params[:category]
    query = params[:query]

    products = Rails.cache.fetch("api_products_#{category_slug}_#{query}", expires_in: 60.seconds) do
      scope = Product.published.includes(:category).order(created_at: :desc)
      scope = scope.joins(:category).where(categories: { slug: category_slug }) if category_slug.present?
      scope = scope.where("products.name LIKE ? OR products.description LIKE ?", "%#{query}%", "%#{query}%") if query.present?
      scope.map { |p| product_json(p) }
    end

    render json: { products: products }
  end

  def show
    product = Rails.cache.fetch("api_product_detail_#{params[:slug]}", expires_in: 60.seconds) do
      p = Product.published.includes(:category, :reviews).find_by!(slug: params[:slug])
      product_json(p, detailed: true)
    end

    render json: { product: product }
  end

  private

  def product_json(p, detailed: false)
    data = {
      id: p.id,
      name: p.name,
      slug: p.slug,
      description: p.description,
      price: p.price,
      stock_quantity: p.stock_quantity,
      stock_status: p.stock_status,
      category: { id: p.category_id, name: p.category.name, slug: p.category.slug },
      average_rating: p.average_rating,
      rating_count: p.rating_count,
      images: p.images.attached? ? p.images.map { |img| url_for(img) } : []
    }
    if detailed
      data[:reviews] = p.reviews.recent.limit(10).map do |r|
        {
          id: r.id,
          rating: r.rating,
          comment: r.comment,
          user_name: r.user.name.presence || r.user.email_address.split("@").first,
          created_at: r.created_at.iso8601
        }
      end
    end
    data
  end
end
