class JobsController < ApplicationController
  def show
    @recent_jobs = fetch_user_jobs
  end

  def trigger
    GenerateSummaryJob.perform_later(Current.user.id)
    redirect_to jobs_test_path, notice: "Solid Queue に非同期ジョブをエンキューしました！"
  end

  private

  def fetch_user_jobs
    return [] unless defined?(SolidQueue::Job)

    # ログインユーザーに関連するジョブのみに制限して取得
    SolidQueue::Job.order(created_at: :desc).limit(50).select do |job|
      user_job?(job, Current.user.id)
    end.first(10)
  rescue StandardError => e
    Rails.logger.error "[JobsController#show] Failed to fetch SolidQueue jobs: #{e.message}"
    flash.now[:alert] = "ジョブ履歴の取得中にエラーが発生しました。"
    []
  end

  def user_job?(job, user_id)
    args = job.arguments
    args = JSON.parse(args) if args.is_a?(String)
    return false unless args.is_a?(Hash)

    job_args = args["arguments"] || []
    args["job_class"] == "GenerateSummaryJob" && job_args.include?(user_id)
  rescue StandardError
    false
  end
end
