module TasksHelper
  # A task may have no due date, so the list needs a readable fallback.
  def task_due_date(task)
    return "No due date" if task.due_date.blank?

    l(task.due_date, format: "%b %-d, %Y")
  end

  def task_status_label(task)
    task.status.titleize
  end
end
