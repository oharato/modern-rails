class Api::Admin::JobsController < Api::BaseController
  before_action :require_admin

  def daily_report
    job = DailySalesReportJob.perform_later(Date.current.to_s)
    render json: { status: "queued", job_id: job.job_id }
  end

  def logs
    logs = JobLog.recent.map do |jl|
      {
        id: jl.id,
        job_type: jl.job_type,
        status: jl.status,
        payload: jl.payload,
        created_at: jl.created_at.iso8601,
        finished_at: jl.finished_at&.iso8601
      }
    end
    render json: { job_logs: logs }
  end
end
