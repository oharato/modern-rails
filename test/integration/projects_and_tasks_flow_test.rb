require "test_helper"

class ProjectsAndTasksFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "full user workflow: create project, then create task under that project via turbo stream" do
    # 1. Visit Dashboard
    get root_url
    assert_response :success

    # 2. Create Project via Turbo Stream
    assert_difference -> { @user.projects.count }, 1 do
      post projects_url, params: { project: { title: "Flow Test Project", color: "amber" } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, "Flow Test Project"

    new_project = @user.projects.find_by(title: "Flow Test Project")
    assert_not_nil new_project

    # 3. Create Task associated with the new project
    assert_difference -> { @user.tasks.count }, 1 do
      post tasks_url, params: { task: { title: "Task under Flow Project", project_id: new_project.id, priority: "urgent" } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.body, "Task under Flow Project"

    # 4. Toggle Task Completion
    task = @user.tasks.find_by(title: "Task under Flow Project")
    patch toggle_task_url(task), as: :turbo_stream
    assert_response :success
    assert task.reload.completed
  end
end
