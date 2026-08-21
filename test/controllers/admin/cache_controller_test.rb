require "test_helper"

class Admin::CacheControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  test "admin can view cache status and purge cache" do
    sign_in_as(@admin)
    Rails.cache.write("catalog_top", "sample_data")
    assert_equal "sample_data", Rails.cache.read("catalog_top")

    get admin_cache_management_url
    assert_response :success

    post admin_purge_cache_url
    assert_redirected_to admin_cache_management_url
    assert_nil Rails.cache.read("catalog_top")
  end
end
