require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  TURBO_STREAM_HEADERS = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    @project = projects(:customer_portal)
    @task = tasks(:portal_login_bug)
  end

  test "project show lists the project's tasks with status and due date" do
    get project_url(@project)

    assert_response :success
    assert_select ".task", count: @project.tasks.count
    assert_select "##{dom_id(@task)}" do
      assert_select ".task-title", @task.title
      assert_select ".task-status", "Pending"
      assert_select ".task-due", "Nov 20, 2026"
    end
  end

  test "project show handles a task without a due date" do
    get project_url(@project)

    assert_select "##{dom_id(tasks(:portal_backlog))} .task-due", "No due date"
  end

  test "project show reports how many tasks are completed" do
    get project_url(@project)

    assert_select "#task_summary", /1 of 4 tasks completed/
  end

  test "project show offers Mark Complete only for incomplete tasks" do
    get project_url(@project)

    assert_select "##{dom_id(tasks(:portal_dashboard))} .task-actions button[type=submit]", "Mark Complete"
    assert_select "##{dom_id(tasks(:portal_documentation))} .task-actions button", count: 0
  end

  test "project show lists an empty state for a project without tasks" do
    get project_url(projects(:internal_operations))

    assert_response :success
    assert_select ".task", count: 0
    assert_select ".empty", "No tasks yet."
  end

  test "create adds the task and returns to the project page" do
    assert_difference("@project.tasks.count", 1) do
      post project_tasks_url(@project),
           params: { task: { title: "Write release notes", status: "in_progress", due_date: "2026-12-01" } }
    end

    assert_redirected_to project_url(@project)
    follow_redirect!
    assert_select ".task-title", text: "Write release notes"

    task = @project.tasks.find_by!(title: "Write release notes")
    assert_equal "in_progress", task.status
    assert_equal Date.new(2026, 12, 1), task.due_date
  end

  test "create accepts a task without a due date" do
    assert_difference("Task.count", 1) do
      post project_tasks_url(@project), params: { task: { title: "Someday", status: "pending", due_date: "" } }
    end

    assert_nil Task.find_by!(title: "Someday").due_date
  end

  test "create with a blank title shows errors and keeps the entered values" do
    assert_no_difference("Task.count") do
      post project_tasks_url(@project),
           params: { task: { title: "", status: "in_progress", due_date: "2026-12-01" } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors li", "Title can't be blank"
    assert_select "select#task_status option[selected][value=?]", "in_progress"
    assert_select "input#task_due_date[value=?]", "2026-12-01"
    # The existing tasks are still listed alongside the errors.
    assert_select ".task", count: @project.tasks.count
  end

  test "Mark Complete updates the status and responds with a turbo stream" do
    patch task_url(@task), params: { task: { status: "completed" } }, headers: TURBO_STREAM_HEADERS

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_predicate @task.reload, :completed?

    assert_select "turbo-stream[action=?][target=?]", "replace", dom_id(@task)
    assert_select "turbo-stream[action=?][target=?]", "replace", "task_summary"
  end

  test "update redirects back to the project for a non-turbo request" do
    patch task_url(@task), params: { task: { status: "completed" } }

    assert_redirected_to project_url(@project)
    assert_predicate @task.reload, :completed?
  end

  test "update rejects an unknown status" do
    patch task_url(@task), params: { task: { status: "archived" } }

    assert_redirected_to project_url(@project)
    assert_equal "pending", @task.reload.status
    follow_redirect!
    assert_select ".flash-alert", /Status is not included in the list/
  end
end
