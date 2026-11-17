class Task < ApplicationRecord
  belongs_to :project

  # Stored as a string so the value is readable in the database. `validate: true`
  # makes an unknown status fail validation instead of raising, which keeps the
  # form's error handling working if an unexpected value is ever submitted.
  enum :status, { pending: "pending", in_progress: "in_progress", completed: "completed" },
       validate: true

  validates :title, presence: true

  # Incomplete tasks first, then the soonest due date.
  # Postgres sorts NULLs last, so tasks without a due date come after dated ones.
  scope :incomplete_first, -> {
    order(Arel.sql("CASE WHEN status = 'completed' THEN 1 ELSE 0 END"), :due_date, :created_at)
  }
end
