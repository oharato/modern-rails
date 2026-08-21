require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
    @category = Category.create!(name: "Crafts", slug: "crafts")
    @product1 = Product.create!(category: @category, name: "Item 1", slug: "item-1", price: 1000, stock_quantity: 10)
    @product2 = Product.create!(category: @category, name: "Item 2", slug: "item-2", price: 2500, stock_quantity: 5)
    @user = User.create!(email_address: "cartuser@example.com", password: "password123")
  end

  test "guest cart adds, updates, and removes items in KV cache" do
    cart = Cart.for_guest("guest-uuid-123")
    assert cart.empty?

    cart.add_item(@product1.id, 2)
    assert_equal 2, cart.total_count
    assert_equal 2000, cart.total_amount

    cart.add_item(@product2.id, 1)
    assert_equal 3, cart.total_count
    assert_equal 4500, cart.total_amount

    cart.update_quantity(@product1.id, 5)
    assert_equal 6, cart.total_count
    assert_equal 7500, cart.total_amount

    cart.remove_item(@product1.id)
    assert_equal 1, cart.total_count
    assert_equal 2500, cart.total_amount

    cart.clear
    assert cart.empty?
  end

  test "guest cart merges to user cart on login" do
    guest_cart = Cart.for_guest("guest-merge-uuid")
    user_cart = Cart.for_user(@user)

    guest_cart.add_item(@product1.id, 2)
    guest_cart.add_item(@product2.id, 1)

    user_cart.add_item(@product1.id, 1)

    Cart.merge(guest_cart, user_cart)

    assert guest_cart.empty?, "Guest cart should be cleared after merge"
    assert_equal 4, user_cart.total_count # 1 + 2 of item1 + 1 of item2
    assert_equal 5500, user_cart.total_amount
  end
end
