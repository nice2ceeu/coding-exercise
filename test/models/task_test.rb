require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @project = projects(:customer_portal)
  end

  test "is valid with just a title, and defaults to pending" do
    task = @project.tasks.build(title: "Write release notes")

    assert task.valid?
    assert_nil task.due_date
    assert_equal "pending", task.status
  end

  test "is invalid without a title" do
    task = @project.tasks.build(title: "")

    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "is invalid without a project" do
    task = Task.new(title: "Orphan")

    assert_not task.valid?
    assert_includes task.errors[:project], "must exist"
  end

  test "allows each of the three statuses" do
    Task.statuses.each_key do |status|
      task = @project.tasks.build(title: "Anything", status: status)

      assert task.valid?, "expected #{status} to be a valid status"
    end
  end

  test "is invalid with an unknown status" do
    task = @project.tasks.build(title: "Anything", status: "archived")

    assert_not task.valid?
    assert_includes task.errors[:status], "is not included in the list"
  end

  test "destroying a project destroys its tasks" do
    assert_operator @project.tasks.count, :>, 0

    assert_difference("Task.count", -@project.tasks.count) do
      @project.destroy!
    end
  end

  test "incomplete_first lists incomplete tasks before completed ones" do
    completed_flags = @project.tasks.incomplete_first.map(&:completed?)

    assert_includes completed_flags, true
    assert_includes completed_flags, false
    assert_equal completed_flags.sort_by { |completed| completed ? 1 : 0 }, completed_flags
  end

  test "incomplete_first orders undated tasks after dated ones" do
    pending_titles = @project.tasks.incomplete_first.select(&:pending?).map(&:title)

    assert_equal [ "Fix login bug", "Triage the support backlog" ], pending_titles
  end
end
