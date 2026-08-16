class DashboardController < ApplicationController
  def index
    @projects = Current.user.projects.order(created_at: :desc)
    @tasks = Current.user.tasks.includes(:project).order(completed: :asc, created_at: :desc)
    @new_task = Task.new
    @new_project = Project.new

    # Solid Cache demo: 5分キャッシュ
    @stats = Rails.cache.fetch(Current.user.stats_cache_key, expires_in: 5.minutes) do
      {
        total_tasks: Current.user.tasks.count,
        completed_tasks: Current.user.tasks.completed.count,
        pending_tasks: Current.user.tasks.pending.count,
        total_projects: Current.user.projects.count,
        cached_at: Time.current
      }
    end
  end
end
