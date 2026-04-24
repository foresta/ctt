///|
/// Interprets a CommandResult tree, performing actual I/O.
/// Delegates output to the Renderer and interaction to ItemSelector/UserPrompter.
pub async fn run(
  result : @ports.CommandResult,
  renderer : &@ports.Renderer,
  selector : &@ports.ItemSelector,
  prompter : &@ports.UserPrompter
) -> Unit {
  match result {
    Lines(lines) => renderer.print_lines(lines)
    Table(rows) => renderer.print_table(rows)
    Empty => ()
    Error(msg) => renderer.print_error(msg)
    Sequence(results) =>
      for result in results {
        run(result, renderer, selector, prompter)
      }
    Then(first~, next~) => {
      run(first, renderer, selector, prompter)
      run(next(), renderer, selector, prompter)
    }
    Confirm(prompt~, on_yes~) => {
      match prompter.confirm(prompt=prompt) {
        Ok(true) => run(on_yes(), renderer, selector, prompter)
        _ => renderer.print_cancelled()
      }
    }
    Select(items~, prompt~, on_select~) => {
      if items.is_empty() {
        renderer.print_error(prompt + " No items found.")
        return
      }
      match selector.select(items=items, prompt=prompt) {
        Ok(Some(selected)) =>
          run(on_select(selected), renderer, selector, prompter)
        _ => renderer.print_cancelled()
      }
    }
    Menu(prompt~, options~) => {
      if options.is_empty() {
        renderer.print_error(prompt + " No items found.")
        return
      }
      let labels = options.map(fn(opt) { opt.0 })
      match selector.select(items=labels, prompt=prompt) {
        Ok(Some(selected)) =>
          match options.iter().find_first(fn(opt) { opt.0 == selected }) {
            Some(opt) => run(opt.1(), renderer, selector, prompter)
            None => renderer.print_cancelled()
          }
        _ => renderer.print_cancelled()
      }
    }
    Input(prompt~, on_input~) => {
      match prompter.read_line(prompt=prompt) {
        Ok(input) if input != "" =>
          run(on_input(input), renderer, selector, prompter)
        _ => renderer.print_cancelled()
      }
    }
  }
}
