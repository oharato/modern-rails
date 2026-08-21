require "test_helper"

class GuideControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get guide_url
    assert_response :success
  end

  test "should get solid_trio" do
    get guide_solid_trio_url
    assert_response :success
  end
end
