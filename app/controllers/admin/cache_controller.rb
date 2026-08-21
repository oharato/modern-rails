module Admin
  class CacheController < BaseController
    def show
      @cache_entries_count = SolidCache::Entry.count rescue 0
      @catalog_top_cached = Rails.cache.exist?("catalog_top")
    end

    def purge
      Rails.cache.clear
      redirect_to admin_cache_management_path, notice: "すべてのキャッシュをパージ（破棄）しました。"
    end
  end
end
