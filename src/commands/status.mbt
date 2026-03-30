///|
/// Converts a TaskStatus enum value to its display string.
fn format_status(status : @ports.TaskStatus) -> String {
  match status {
    InProgress => "in-progress"
    PrOpen => "pr-open"
    Merged => "merged"
    NoChanges => "no-changes"
  }
}

///|
/// Pads a string with trailing spaces to reach the given width.
fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    return s
  }
  let buf = StringBuilder::new()
  buf.write_string(s)
  for i = len; i < width; i = i + 1 {
    buf.write_char(' ')
  }
  buf.to_string()
}

///|
/// Prints rows as a column-aligned table, auto-sizing each column to its widest cell.
fn print_table(rows : Array[Array[String]]) -> Unit {
  let col_count = rows[0].length()
  let widths = Array::make(col_count, 0)
  for row in rows {
    for i, cell in row {
      if cell.length() > widths[i] {
        widths[i] = cell.length()
      }
    }
  }
  for row in rows {
    let buf = StringBuilder::new()
    for i, cell in row {
      if i > 0 {
        buf.write_string("  ")
      }
      if i < col_count - 1 {
        buf.write_string(pad_right(cell, widths[i]))
      } else {
        buf.write_string(cell)
      }
    }
    println(buf.to_string())
  }
}

///|
/// Shows git and PR status for tasks. Supports `--all` for a summary table or interactive single-task view.
pub(all) struct StatusCommand {
  selector : &@ports.ItemSelector
  repo : &@ports.RepositoryQuery
  tasks : &@task.TaskRepository
  params : Array[String]
}

///|
/// Displays task status: a table of all tasks with `--all`, or an interactive single-task detail view.
impl Runnable for StatusCommand with run(self) {
  let show_all = self.params.length() > 0 && self.params[0] == "--all"
  let task_list = match self.tasks.list() {
    Ok(t) => t
    Err(e) => { println("Error: \{e}"); return }
  }
  if task_list.is_empty() {
    println("No active tasks.")
    return
  }
  if show_all {
    let header = ["TASK", "STATUS", "BRANCH", "CHANGED", "AHEAD", "PR"]
    let rows : Array[Array[String]] = [header]
    for t in task_list {
      match self.repo.get_task_status(workdir=t.workdir) {
        Ok(info) =>
          rows.push(
            [
              t.name,
              format_status(info.status),
              info.branch,
              "\{info.uncommitted} changed",
              "\{info.commits_ahead} commits",
              info.pr_url,
            ],
          )
        Err(e) => rows.push([t.name, "error", e, "", "", ""])
      }
    }
    print_table(rows)
    return
  }
  let names = task_list.map(fn(t) { t.name })
  let selected = match self.selector.select(
    items=names,
    prompt="Select Task> ",
  ) {
    Ok(s) => s
    Err(e) => { println("Error: \{e}"); return }
  }
  match selected {
    None => println("Cancelled.")
    Some(name) => {
      let workdir = task_list
        .iter()
        .find_first(fn(t) { t.name == name })
        .map(fn(t) { t.workdir })
        .unwrap_or("")
      println("Task: \{name}")
      println("---")
      match self.repo.get_task_status(workdir=workdir) {
        Ok(info) =>
          println(
            "\{format_status(info.status)}\t\{info.branch}\t\{info.uncommitted} changed\t\{info.commits_ahead} commits\t\{info.pr_url}",
          )
        Err(e) => println("Error: \{e}")
      }
    }
  }
}
