require "test_helper"

class Admin::JobsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:admin)
  end

  test "admin can view jobs and trigger daily report" do
    sign_in_as(@admin)
    get admin_jobs_url
    assert_response :success

    assert_enqueued_with(job: DailySalesReportJob) do
      post admin_trigger_daily_report_url
    end
    assert_redirected_to admin_jobs_url
  end
end
