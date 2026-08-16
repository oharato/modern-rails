require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { email_address: @user.email_address, password: "password" }
    assert_response :redirect
  end

  test "should create project with HTML format" do
    assert_difference -> { @user.projects.count }, 1 do
      post projects_url, params: { project: { title: "New Project HTML", color: "blue" } }
    end
    assert_redirected_to root_url
    assert_equal "プロジェクト「New Project HTML」を作成しました。", flash[:notice]
  end

  test "should create project with Turbo Stream format" do
    assert_difference -> { @user.projects.count }, 1 do
      post projects_url, params: { project: { title: "New Project Turbo", color: "purple" } }, as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.media_type, "text/vnd.turbo-stream.html"
    assert_match 'target="projects_list"', @response.body
    assert_match 'action="prepend"', @response.body
    assert_match "New Project Turbo", @response.body
    assert_match 'target="new_project_form"', @response.body
    assert_match 'target="new_task_form"', @response.body
  end

  test "should destroy project with Turbo Stream format" do
    project = @user.projects.create!(title: "To Delete", color: "rose")
    assert_difference -> { @user.projects.count }, -1 do
      delete project_url(project), as: :turbo_stream
    end
    assert_response :success
    assert_includes @response.media_type, "text/vnd.turbo-stream.html"
    assert_match %(target="project_#{project.id}"), @response.body
    assert_match 'action="remove"', @response.body
  end

  test "should handle project validation failure with Turbo Stream (status 422)" do
    assert_no_difference -> { @user.projects.count } do
      post projects_url, params: { project: { title: "", color: "rose" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_includes @response.media_type, "text/vnd.turbo-stream.html"
    assert_match 'target="new_project_form"', @response.body
    assert_match 'action="replace"', @response.body
  end
end
