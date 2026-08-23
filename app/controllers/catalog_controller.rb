class CatalogController < ApplicationController
  allow_unauthenticated_access

  def index
    # 60-second edge/server catalog cache
    @catalog_data = Rails.cache.fetch("catalog_top", expires_in: 60.seconds) do
      {
        featured_products: Product.published.featured.includes(:category).with_attached_images.to_a,
        recent_products: Product.published.recent.includes(:category).with_attached_images.to_a,
        categories: Category.all.to_a
      }
    end

    @featured_products = @catalog_data[:featured_products]
    @recent_products = @catalog_data[:recent_products]
    @categories = @catalog_data[:categories]

    # Dynamic per-user KV data
    @recently_viewed_products = current_recently_viewed.products
  end
end
