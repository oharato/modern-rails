class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]

  def create
    @project = Current.user.projects.build(project_params)

    respond_to do |format|
      if @project.save
        # キャッシュ無効化
        Rails.cache.delete("user_#{Current.user.id}_stats")
        format.html { redirect_to root_path, notice: "プロジェクト「#{@project.title}」を作成しました。" }
        format.turbo_stream
      else
        format.html { redirect_to root_path, alert: "プロジェクトの作成に失敗しました。" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_project_form", partial: "projects/form", locals: { project: @project }) }
      end
    end
  end

  def destroy
    @project.destroy
    Rails.cache.delete("user_#{Current.user.id}_stats")
    respond_to do |format|
      format.html { redirect_to root_path, notice: "プロジェクトを削除しました。" }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, :color)
  end
end
