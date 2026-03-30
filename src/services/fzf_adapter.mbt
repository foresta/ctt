///|
pub(all) struct FzfSelector {}

///|
impl @ports.ItemSelector for FzfSelector with select(self, items~, prompt~) {
  let _ = self
  let result = fzf_select(items, prompt=prompt)
  Ok(result)
}

///|
impl @ports.ItemSelector for FzfSelector with select_with_query(self, items~, prompt~) {
  let _ = self
  let (query, selected) = fzf_select_with_query(items, prompt=prompt)
  Ok(@ports.SelectionResult::{ query, selected })
}
