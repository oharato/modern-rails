require "test_helper"

class JobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get jobs show" do
    get jobs_test_url
    assert_response :success
    assert_select "h1", "Solid Queue 非同期ジョブテスト"
  end

  test "should trigger job" do
    assert_enqueued_with(job: GenerateSummaryJob, args: [ @user.id ]) do
      post trigger_jobs_url
    end
    assert_redirected_to jobs_test_url
  end
end
