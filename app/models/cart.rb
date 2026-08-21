class Cart
  Item = Struct.new(:product_id, :quantity, :price_at_add, :product) do
    def subtotal
      (price_at_add || product&.price || 0) * quantity
    end
  end

  attr_reader :cache_key, :expires_in

  def initialize(cache_key, expires_in:)
    @cache_key = cache_key
    @expires_in = expires_in
  end

  def self.for_user(user)
    new("cart:user_#{user.id}", expires_in: 30.days)
  end

  def self.for_guest(guest_session_id)
    new("cart:guest_#{guest_session_id}", expires_in: 7.days)
  end

  def self.merge(guest_cart, user_cart)
    return unless guest_cart && user_cart
    guest_items = guest_cart.raw_items
    return if guest_items.empty?

    guest_items.each do |item|
      user_cart.add_item(item["product_id"], item["quantity"].to_i, item["price_at_add"].to_i)
    end

    guest_cart.clear
  end

  def raw_items
    data = Rails.cache.read(@cache_key) || {}
    data["items"] || []
  end

  def items
    raw = raw_items
    return [] if raw.empty?

    product_ids = raw.map { |i| i["product_id"] }
    products_by_id = Product.where(id: product_ids).index_by(&:id)

    raw.filter_map do |item|
      prod = products_by_id[item["product_id"]]
      next unless prod
      Item.new(
        item["product_id"],
        item["quantity"].to_i,
        item["price_at_add"] || prod.price,
        prod
      )
    end
  end

  def add_item(product_id, quantity = 1, price = nil)
    product_id = product_id.to_i
    quantity = quantity.to_i
    return if quantity <= 0

    product = Product.find_by(id: product_id)
    return unless product

    price ||= product.price
    current = raw_items.dup
    existing = current.find { |i| i["product_id"] == product_id }

    if existing
      existing["quantity"] = existing["quantity"].to_i + quantity
      existing["price_at_add"] = price
    else
      current << {
        "product_id" => product_id,
        "quantity" => quantity,
        "price_at_add" => price
      }
    end

    save_items(current)
  end

  def update_quantity(product_id, quantity)
    product_id = product_id.to_i
    quantity = quantity.to_i
    current = raw_items.dup

    if quantity <= 0
      current.reject! { |i| i["product_id"] == product_id }
    else
      existing = current.find { |i| i["product_id"] == product_id }
      if existing
        existing["quantity"] = quantity
      end
    end

    save_items(current)
  end

  def remove_item(product_id)
    product_id = product_id.to_i
    current = raw_items.dup
    current.reject! { |i| i["product_id"] == product_id }
    save_items(current)
  end

  def clear
    Rails.cache.delete(@cache_key)
  end

  def total_count
    raw_items.sum { |i| i["quantity"].to_i }
  end

  def total_amount
    items.sum(&:subtotal)
  end

  def empty?
    raw_items.empty?
  end

  private

  def save_items(items)
    Rails.cache.write(@cache_key, { "items" => items }, expires_in: @expires_in)
  end
end
