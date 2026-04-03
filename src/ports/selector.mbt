///|
/// Result of a user selection interaction, containing both the query text
/// and the optionally selected item.
pub(all) struct SelectionResult {
  query : String
  selected : String?
}

///|
/// Port for interactive item selection from a list.
/// Adapters provide fuzzy-finder or menu-based implementations.
pub(open) trait ItemSelector {
  async select(Self, items~ : Array[String], prompt~ : String) -> Result[String?, String]
  async select_with_query(Self, items~ : Array[String], prompt~ : String) -> Result[SelectionResult, String]
}
