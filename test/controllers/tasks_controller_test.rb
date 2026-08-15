require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should create task without project (optional project_id)" do
    assert_difference("@user.tasks.count", 1) do
      post tasks_url, params: { task: { title: "Standalone Task", project_id: "", priority: "high" } }
    end
    assert_redirected_to root_url
  end

  test "should create task with Turbo Stream" do
    assert_difference("@user.tasks.count", 1) do
      post tasks_url, params: { task: { title: "Turbo Task", priority: "urgent" } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.media_type, "text/vnd.turbo-stream.html"
    assert_match 'target="tasks_list"', @response.body
    assert_match 'action="prepend"', @response.body
    assert_match "Turbo Task", @response.body
  end

  test "should toggle task completion" do
    task = @user.tasks.create!(title: "Toggle Me", completed: false)
    patch toggle_task_url(task), as: :turbo_stream
    assert_response :success
    assert task.reload.completed
  end

  test "should destroy task" do
    task = @user.tasks.create!(title: "Delete Me")
    assert_difference("@user.tasks.count", -1) do
      delete task_url(task), as: :turbo_stream
    end
    assert_response :success
    assert_match %(target="task_#{task.id}"), @response.body
    assert_match 'action="remove"', @response.body
  end
end
