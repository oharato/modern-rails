require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email address" do
    user = User.new(email_address: "  TEST@Example.COM  ", password: "password")
    assert_equal "test@example.com", user.email_address
  end

  test "invalid with duplicate email" do
    existing = users(:one)
    duplicate = User.new(email_address: existing.email_address, password: "password")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "invalid with malformed email" do
    user = User.new(email_address: "invalid-email", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "stats_cache_key helper" do
    user = users(:one)
    assert_equal "user_#{user.id}_stats", user.stats_cache_key
  end
end
