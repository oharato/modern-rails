class Api::Admin::ProductsController < Api::BaseController
  before_action :require_admin

  def create
    product = Product.new(product_params)
    if product.save
      product.purge_catalog_cache
      render json: { status: "success", product: product }, status: :created
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    product = Product.find(params[:id])
    if product.update(product_params)
      product.purge_catalog_cache
      render json: { status: "success", product: product }
    else
      render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.permit(:name, :slug, :description, :price, :stock_quantity, :category_id, :is_published)
  end
end
