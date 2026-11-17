class TasksController < ApplicationController
  def create
    @project = Project.find(params.expect(:project_id))
    @task = @project.tasks.build(task_params)

    if @task.save
      redirect_to @project, notice: "Task was successfully created."
    else
      # Re-render the project page so the errors appear next to the form with
      # the submitted values still filled in.
      @tasks = @project.tasks.incomplete_first
      render "projects/show", status: :unprocessable_entity
    end
  end

  def update
    @task = Task.find(params.expect(:id))

    if @task.update(task_params)
      respond_to do |format|
        # "Mark Complete" submits with Turbo, so only the task row and the
        # completed counter are replaced instead of reloading the page.
        format.turbo_stream
        format.html { redirect_to @task.project, notice: "Task was successfully updated." }
      end
    else
      redirect_to @task.project, alert: @task.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def task_params
    params.expect(task: [ :title, :status, :due_date ])
  end
end
