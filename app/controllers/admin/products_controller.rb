module Admin
  class ProductsController < BaseController
    before_action :set_product, only: %i[show edit update destroy toggle_publish update_stock]

    def index
      @products = Product.includes(:category).order(created_at: :desc)
    end

    def show
    end

    def new
      @product = Product.new
      @categories = Category.all
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "商品を登録しました。"
      else
        @categories = Category.all
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.all
    end

    def update
      if @product.update(product_params)
        broadcast_stock_change(@product)
        redirect_to admin_products_path, notice: "商品情報を更新しました。"
      else
        @categories = Category.all
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "商品を削除しました。"
    end

    def toggle_publish
      @product.update!(is_published: !@product.is_published)
      redirect_to admin_products_path, notice: "公開ステータスを変更しました。"
    end

    def update_stock
      new_stock = params[:stock_quantity].to_i
      @product.update!(stock_quantity: new_stock)
      broadcast_stock_change(@product)

      respond_to do |format|
        format.html { redirect_to admin_products_path, notice: "在庫数を更新しました。" }
        format.turbo_stream
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :slug, :description, :price, :stock_quantity, :category_id, :is_published, images: [])
    end

    def broadcast_stock_change(product)
      product.purge_catalog_cache
      Turbo::StreamsChannel.broadcast_replace_to(
        "product_inventory_#{product.id}",
        target: "product_stock_badge_#{product.id}",
        partial: "products/stock_badge",
        locals: { product: product }
      )
    rescue => e
      Rails.logger.warn "Failed to broadcast stock change: #{e.message}"
    end
  end
end
