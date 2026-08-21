class RecentlyViewed
  MAX_ITEMS = 6

  attr_reader :cache_key, :expires_in

  def initialize(cache_key, expires_in: 30.days)
    @cache_key = cache_key
    @expires_in = expires_in
  end

  def self.for_user(user)
    new("recently_viewed:user_#{user.id}")
  end

  def self.for_guest(guest_session_id)
    new("recently_viewed:guest_#{guest_session_id}")
  end

  def product_ids
    Rails.cache.read(@cache_key) || []
  end

  def record(product_id)
    product_id = product_id.to_i
    ids = product_ids.dup
    ids.delete(product_id)
    ids.unshift(product_id)
    ids = ids.first(MAX_ITEMS)
    Rails.cache.write(@cache_key, ids, expires_in: @expires_in)
  end

  def products
    ids = product_ids
    return [] if ids.empty?

    products_by_id = Product.published.where(id: ids).index_by(&:id)
    ids.filter_map { |id| products_by_id[id] }
  end
end
