require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email address" do
    user = User.new(email_address: "  TEST@Example.COM  ", password: "password")
    assert_equal "test@example.com", user.email_address
  end

  test "invalid with duplicate email" do
    existing = users(:customer)
    duplicate = User.new(email_address: existing.email_address, password: "password")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "invalid with malformed email" do
    user = User.new(email_address: "invalid-email", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "roles helper" do
    admin = users(:admin)
    customer = users(:customer)
    assert admin.admin?
    assert_not admin.customer?
    assert customer.customer?
    assert_not customer.admin?
  end
end
