///|
pub(all) struct SelectionResult {
  query : String
  selected : String?
}

///|
pub(open) trait ItemSelector {
  async select(Self, items~ : Array[String], prompt~ : String) -> Result[String?, String]
  async select_with_query(Self, items~ : Array[String], prompt~ : String) -> Result[SelectionResult, String]
}
