///|
/// Adapter that implements the ItemSelector port using fzf.
pub(all) struct FzfSelector {}

///|
/// Select a single item from the list using fzf.
impl @ports.ItemSelector for FzfSelector with select(self, items~, prompt~) {
  let _ = self
  let result = fzf_select(items, prompt=prompt)
  Ok(result)
}

///|
/// Select an item with query text returned alongside the selection.
impl @ports.ItemSelector for FzfSelector with select_with_query(self, items~, prompt~) {
  let _ = self
  let (query, selected) = fzf_select_with_query(items, prompt=prompt)
  Ok(@ports.SelectionResult::{ query, selected })
}
