require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid with title and user" do
    project = @user.projects.build(title: "New Project", color: "blue")
    assert project.valid?
  end

  test "invalid without title" do
    project = @user.projects.build(title: "", color: "blue")
    assert_not project.valid?
    assert_includes project.errors[:title], "can't be blank"
  end

  test "destroys associated tasks upon project deletion" do
    project = @user.projects.create!(title: "Project with tasks", color: "blue")
    @user.tasks.create!(title: "Task 1", project: project)
    @user.tasks.create!(title: "Task 2", project: project)

    assert_difference("@user.tasks.count", -2) do
      project.destroy
    end
  end
end
