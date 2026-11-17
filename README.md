# Project Tracker — Rails Take-Home Starter

Starter repository for Codevelopr's Junior Ruby on Rails Developer take-home exercise.

> **This repository is intentionally incomplete.** The missing Task functionality is part of the coding exercise.
> **Start with [TAKE_HOME.md](TAKE_HOME.md).**

The app is a small Rails 8 / Hotwire application that already supports full CRUD for **Projects**.

## Requirements

- Ruby 3.4.x (developed with 3.4.8; see `.ruby-version`)
- PostgreSQL, running locally (the default `config/database.yml` connects over the local socket as your OS user)
- Node is **not** required (Importmap, no JS build step)

## Setup

```bash
bin/setup
```

This installs gems, creates and migrates the database, loads the seed data and starts the server.
To set up without starting the server, run `bin/setup --skip-server`.

Manual alternative:

```bash
bundle install
bin/rails db:prepare db:seed
```

## Run

```bash
bin/rails server
```

Then open <http://localhost:3000>.

## Test

```bash
bin/rails test
```

The starting test suite should pass before you change anything.

## Exercise

Full instructions are in [TAKE_HOME.md](TAKE_HOME.md). Timebox: about 60 minutes.

### What to do

1. Fork this repository and clone your fork.
2. Run `bin/setup` and `bin/rails test` to confirm the starter works.
3. Add **Tasks** to Projects (a Project has many Tasks; a Task belongs to one Project).
4. Commit your work to your fork, add your notes to the sections at the bottom of this README, and send us the URL of your public fork.

### Acceptance criteria

**Required**

- [x] **Model and database:** a `Task` model with `project_id`, `title`, `status` and `due_date`, using appropriate column types and a database foreign key to `projects`. The due date is optional.
- [x] **Relationships:** `Project has_many :tasks, dependent: :destroy` and `Task belongs_to :project`. Deleting a project deletes its tasks.
- [x] **Validations:** a task requires a title; status is limited to `pending`, `in_progress` and `completed`; a project still requires a name.
- [x] **Show page:** `/projects/:id` lists the project's tasks, each with title, status and due date, and the "not implemented yet" placeholder is removed.
- [x] **Create task:** the Project page has a form (Title, Status, Due Date). A valid submission shows the new task and keeps the user on the Project page. An invalid submission shows meaningful errors and keeps the entered values where reasonable.
- [x] **Mark Complete:** every incomplete task has a **Mark Complete** control that sets its status to `completed` without a full page reload (Turbo, Stimulus, `fetch` or vanilla JS are all fine).
- [x] **Styling:** Pending, In Progress and Completed are visually distinct and the list is easy to read.
- [x] **Conventions:** RESTful routes and controller actions, strong parameters, `form_with`, path helpers. The existing tests still pass.
- [x] **README:** the "millions of tasks" question is answered and any unfinished work is noted.

**Bonus (only after the required items)**

- [x] Show "3 of 5 tasks completed" on the Project page.
- [x] At least one meaningful automated test for the Task functionality.
- [x] Sort tasks so incomplete ones appear before completed ones.

**Also**

- [x] If you used AI tools, say which and what for. Be ready to explain all of your code in the follow-up interview.

---

<!-- Candidates: replace everything below this line with your own notes. -->

## Submission notes

All required items and all three bonus items are implemented.

### How it is put together

- **Model and database** — `db/migrate/20261118090000_create_tasks.rb` creates `tasks` with
  `t.references :project, null: false, foreign_key: true` (so the database enforces the
  relationship and indexes `project_id`), `title` as a non-null string, `status` as a string
  defaulting to `"pending"`, and a nullable `due_date` of type `date`.
- **Status** — `Task` uses `enum :status, { ... }, validate: true`. The enum gives the
  `completed?` predicate and the `completed` scope used by the counter, and `validate: true`
  makes an unexpected value fail validation instead of raising, so the form keeps working.
- **Routing** — tasks are nested under projects but `shallow: true`, so creating a task posts to
  `/projects/:project_id/tasks` while updating one patches `/tasks/:id`.
- **Create** — `TasksController#create` redirects back to the project on success. On failure it
  re-renders `projects/show` with `:unprocessable_entity`, which keeps the submitted title,
  status and due date in the form because the same invalid `@task` is used to build it.
- **Mark Complete** — the button is a `button_to` with `method: :patch` and a hidden
  `task[status]=completed` parameter, so it is an ordinary RESTful update with strong parameters.
  Turbo submits it, and `app/views/tasks/update.turbo_stream.erb` returns two turbo streams that
  replace only the task's `<li>` and the completed counter — no full page reload. The HTML format
  still redirects, so the control degrades gracefully without JavaScript.
- **Sorting (Bonus C)** — `Task.incomplete_first` orders completed tasks last, then by soonest
  due date. Postgres sorts `NULL` last by default, so undated tasks naturally fall to the end.

### Running the tests

```bash
bin/rails test
```

New tests: `test/models/task_test.rb` (validations, the `dependent: :destroy` cascade, ordering)
and `test/controllers/tasks_controller_test.rb` (the show page listing, creating a task with and
without a due date, validation errors preserving input, and Mark Complete returning a turbo
stream). `test/fixtures/tasks.yml` deliberately includes one task with no due date.

### Assumptions

- Statuses are stored as strings rather than integers, so the column is readable in the database.
  The allowed values are enforced in the model; a database check constraint would be the next
  step if other writers ever touched the table.
- The task counter runs two `COUNT` queries. That is clear and cheap at this size, and it keeps
  the counter correct when it is re-rendered on its own by the turbo stream.
- There is no edit, show or delete action for tasks, because the exercise did not ask for them.

## If this application eventually contained millions of tasks, what database or query changes would you consider?

The project page is the hot path, so the first thing I would do is index for it. `project_id` is
already indexed by `t.references`; I would replace that with a composite
`[project_id, status, due_date]` index so filtering, ordering and the completed count for one
project are all served by a single index, and check `EXPLAIN ANALYZE` rather than guessing.

Beyond indexing:

- **Paginate.** Never render every task for a project. Load a page at a time, which also caps
  the memory and HTML size per request.
- **Stop counting rows on every page view.** `COUNT(*)` gets slow at this scale. I would use a
  `tasks_count` / `completed_tasks_count` counter cache on `projects`, maintained by
  `counter_culture` or an `after_commit` hook, so the "3 of 5" line is a single column read.
- **Avoid N+1 queries.** Any list of projects that shows task data would use
  `includes(:tasks)` or the counter caches above.
- **Make the ordering index-friendly.** The `CASE WHEN status = 'completed'` ordering cannot use
  an index. With millions of rows I would store a sortable column instead — for example an
  integer status, or a boolean `completed` flag — so the sort is a plain index scan.
- **Keep the working set small.** Most queries only care about open tasks, so a partial index
  (`WHERE status <> 'completed'`) would stay small even as completed tasks accumulate. Further
  out, archiving or partitioning completed tasks by date, and moving reporting queries to a read
  replica, would keep the interactive path fast.

## AI tools

I used **Claude (Claude Code)** for this exercise, for:

- scaffolding the migration, model, controller, views, tests and CSS from the requirements in
  `TAKE_HOME.md`;
- discussing how to constrain `status` (`enum ..., validate: true` versus a plain inclusion
  validation) and how to express the "incomplete first" ordering in SQL;
- drafting these README notes.

I reviewed every line and can explain all of it.
