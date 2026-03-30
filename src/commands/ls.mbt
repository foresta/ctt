///|
pub(all) struct LsCommand {
  tasks : &@task.TaskRepository
}

///|
impl Runnable for LsCommand with run(self) {
  match self.tasks.list() {
    Ok(tasks) =>
      if tasks.is_empty() {
        println("No active tasks.")
      } else {
        tasks.each(fn(t) { println(t.name) })
      }
    Err(e) => println("Error: \{e}")
  }
}
