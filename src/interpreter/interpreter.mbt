///|
/// Interprets a CommandResult tree, performing actual I/O.
/// Delegates output to the Renderer and interaction to ItemSelector/UserPrompter.
/// Returns false when the result contained an error or the user cancelled.
pub async fn run(
  result : @ports.CommandResult,
  renderer : &@ports.Renderer,
  selector : &@ports.ItemSelector,
  prompter : &@ports.UserPrompter
) -> Bool {
  match result {
    Lines(lines) => {
      renderer.print_lines(lines)
      true
    }
    Table(rows) => {
      renderer.print_table(rows)
      true
    }
    Empty => true
    Error(msg) => {
      renderer.print_error(msg)
      false
    }
    Sequence(results) => {
      let mut ok = true
      for result in results {
        if !run(result, renderer, selector, prompter) {
          ok = false
        }
      }
      ok
    }
    Then(first~, next~) =>
      if run(first, renderer, selector, prompter) {
        run(next(), renderer, selector, prompter)
      } else {
        false
      }
    Confirm(prompt~, on_yes~) =>
      match prompter.confirm(prompt=prompt) {
        Ok(true) => run(on_yes(), renderer, selector, prompter)
        _ => {
          renderer.print_cancelled()
          false
        }
      }
    Select(items~, prompt~, on_select~) => {
      if items.is_empty() {
        renderer.print_error(prompt + " No items found.")
        return false
      }
      match selector.select(items=items, prompt=prompt) {
        Ok(Some(selected)) =>
          run(on_select(selected), renderer, selector, prompter)
        _ => {
          renderer.print_cancelled()
          false
        }
      }
    }
    Menu(prompt~, options~) => {
      if options.is_empty() {
        renderer.print_error(prompt + " No items found.")
        return false
      }
      let labels = options.map(fn(opt) { opt.0 })
      match selector.select(items=labels, prompt=prompt) {
        Ok(Some(selected)) =>
          match options.iter().find_first(fn(opt) { opt.0 == selected }) {
            Some(opt) => run(opt.1(), renderer, selector, prompter)
            None => {
              renderer.print_cancelled()
              false
            }
          }
        _ => {
          renderer.print_cancelled()
          false
        }
      }
    }
    Input(prompt~, on_input~) =>
      match prompter.read_line(prompt=prompt) {
        Ok(input) if input != "" =>
          run(on_input(input), renderer, selector, prompter)
        _ => {
          renderer.print_cancelled()
          false
        }
      }
  }
}
