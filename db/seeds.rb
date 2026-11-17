# Safe to run repeatedly: projects and tasks are looked up before being created.
[
  {
    name: "Customer Portal",
    description: "Customer-facing account and billing application.",
    tasks: [
      { title: "Fix login bug",        status: "pending",     due_date: Date.current + 2.days },
      { title: "Create dashboard",     status: "in_progress", due_date: Date.current + 4.days },
      { title: "Update documentation", status: "completed",   due_date: Date.current + 7.days },
      { title: "Triage support backlog", status: "pending",   due_date: nil }
    ]
  },
  {
    name: "Internal Operations",
    description: "Internal staff workflow tools.",
    tasks: [
      { title: "Draft onboarding checklist", status: "in_progress", due_date: Date.current + 10.days },
      { title: "Archive 2025 reports",       status: "completed",   due_date: Date.current - 5.days }
    ]
  },
  {
    name: "Mobile App",
    description: "Companion mobile application.",
    tasks: []
  }
].each do |attributes|
  project = Project.find_or_create_by!(name: attributes[:name]) do |record|
    record.description = attributes[:description]
  end

  attributes[:tasks].each do |task_attributes|
    project.tasks.find_or_create_by!(title: task_attributes[:title]) do |task|
      task.status = task_attributes[:status]
      task.due_date = task_attributes[:due_date]
    end
  end
end
