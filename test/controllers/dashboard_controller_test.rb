require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
  end

  test "unauthenticated user is redirected to login" do
    get dashboard_url
    assert_redirected_to new_session_url
  end

  test "authenticated user can view dashboard" do
    sign_in_as(@user)
    get dashboard_url
    assert_response :success
    assert_select "h1", text: /#{@user.name}|マイダッシュボード/
  end
end
