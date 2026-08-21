require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @customer = users(:customer)
  end

  test "admin can access dashboard" do
    sign_in_as(@admin)
    get admin_root_url
    assert_response :success
    assert_select "h1", "売上ダッシュボード"
  end

  test "non-admin customer is forbidden from admin dashboard" do
    sign_in_as(@customer)
    get admin_root_url
    assert_redirected_to root_url
  end
end
