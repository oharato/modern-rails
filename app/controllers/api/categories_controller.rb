class Api::CategoriesController < Api::BaseController
  allow_unauthenticated_access

  def index
    categories = Rails.cache.fetch("api_categories_all", expires_in: 60.seconds) do
      Category.all.map do |c|
        {
          id: c.id,
          name: c.name,
          slug: c.slug,
          description: c.description,
          products_count: c.products.published.count
        }
      end
    end

    render json: { categories: categories }
  end
end
