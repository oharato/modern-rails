class TasksController < ApplicationController
  before_action :set_task, only: %i[toggle destroy]

  def create
    @task = Current.user.tasks.build(task_params)

    respond_to do |format|
      if @task.save
        Rails.cache.delete("user_#{Current.user.id}_stats")
        format.html { redirect_to root_path, notice: "タスクを追加しました。" }
        format.turbo_stream
      else
        format.html { redirect_to root_path, alert: "タスクの追加に失敗しました。" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_task_form", partial: "tasks/form", locals: { task: @task }) }
      end
    end
  end

  def toggle
    @task.update(completed: !@task.completed)
    Rails.cache.delete("user_#{Current.user.id}_stats")

    respond_to do |format|
      format.html { redirect_to root_path }
      format.turbo_stream
    end
  end

  def destroy
    @task.destroy
    Rails.cache.delete("user_#{Current.user.id}_stats")

    respond_to do |format|
      format.html { redirect_to root_path, notice: "タスクを削除しました。" }
      format.turbo_stream
    end
  end

  private

  def set_task
    @task = Current.user.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :project_id, :priority, :due_date)
  end
end
