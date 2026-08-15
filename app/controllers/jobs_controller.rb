class JobsController < ApplicationController
  def show
    @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(10) rescue []
  end

  def trigger
    GenerateSummaryJob.perform_later(Current.user.id)
    redirect_to jobs_test_path, notice: "Solid Queue に非同期ジョブをエンキューしました！"
  end
end
