require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @project = projects(:one)
    @other_project = projects(:two)
  end

  test "valid with title and same user project" do
    task = @user.tasks.build(title: "My Task", project: @project)
    assert task.valid?
  end

  test "valid without project" do
    task = @user.tasks.build(title: "My Task", project: nil)
    assert task.valid?
  end

  test "invalid without title" do
    task = @user.tasks.build(title: "", project: @project)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "invalid when associating with another user's project (IDOR protection)" do
    task = @user.tasks.build(title: "Hacked Task", project: @other_project)
    assert_not task.valid?
    assert_includes task.errors[:project], "must belong to the same user"
  end
end
