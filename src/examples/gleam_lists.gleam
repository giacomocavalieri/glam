import gleam/int
import gleam/io
import gleam/list
import gleam/string
import glam/doc.{Document}

/// Pretty prints a list of strings:
/// - each string is surrounded by quotes
/// - each string is separated by a comma and a space
/// - if the list does not fit on one line each one of its items should be on
///   a newline and indented
/// 
/// ## Examples
/// 
/// ```
/// > let list = ["Gleam", "is", "fun!"] |> pretty_list
/// > list |> doc.to_string(30)
/// ["Gleam", "is", "fun!"]
/// 
/// > list |> doc.to_string(6)
/// [
///   "Gleam",
///   "is",
///   "fun!",
/// ]
/// ```
/// 
fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let comma = doc.concat([doc.from_string(","), doc.space])
  let open_square = doc.concat([doc.from_string("["), doc.soft_break])
  let trailing_comma = doc.break(",", "")
  let close_square = doc.concat([trailing_comma, doc.from_string("]")])

  list.map(list, list_item_to_document)
  |> doc.join(with: comma)
  |> doc.prepend(open_square)
  |> doc.nest(by: 2)
  |> doc.append(close_square)
  |> doc.group
}

pub fn main() {
  use max_width <- list.each([10, 20, 30])
  io.println("Max width: " <> int.to_string(max_width))
  io.println(string.repeat("-", max_width))

  ["Gleam", "is", "fun!"]
  |> pretty_list
  |> doc.to_string(max_width)
  |> io.println
  io.println("")
}
