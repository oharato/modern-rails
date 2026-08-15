class GenerateSummaryJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # 重い処理のシミュレーション
    sleep 2

    # キャッシュを更新
    Rails.cache.write("user_#{user.id}_stats", {
      total_tasks: user.tasks.count,
      completed_tasks: user.tasks.completed.count,
      pending_tasks: user.tasks.pending.count,
      total_projects: user.projects.count,
      cached_at: Time.current,
      job_processed_at: Time.current
    }, expires_in: 5.minutes)

    Rails.logger.info "[SolidQueue] GenerateSummaryJob finished for user #{user.id}"
  end
end
