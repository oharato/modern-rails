class Api::Admin::CacheController < Api::BaseController
  before_action :require_admin

  def purge
    Rails.cache.clear
    render json: { status: "success", message: "Catalog cache purged successfully" }
  end
end
