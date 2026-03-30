///|
pub(open) trait TaskRepository {
  list(Self) -> Result[Array[Task], String]
  find(Self, name~ : String) -> Result[Task?, String]
}
