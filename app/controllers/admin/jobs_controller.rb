module Admin
  class JobsController < BaseController
    def index
      @job_logs = JobLog.recent
    end

    def trigger_daily_report
      DailySalesReportJob.perform_later(Date.current.to_s)
      redirect_to admin_jobs_path, notice: "日次売上集計ジョブをキューに追加しました。"
    end
  end
end
