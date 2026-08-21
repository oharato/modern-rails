class Api::RecentlyViewedController < Api::BaseController
  allow_unauthenticated_access

  def index
    products = current_recently_viewed.products.map do |p|
      {
        id: p.id,
        name: p.name,
        slug: p.slug,
        price: p.price,
        stock_status: p.stock_status
      }
    end

    render json: { products: products }
  end
end
