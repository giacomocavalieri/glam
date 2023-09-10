import gleam/int
import gleam/io
import gleam/list
import gleam/string
import glam/doc.{Document}

type Span {
  Span(line: Int, column_start: Int, column_end: Int)
}

type Error {
  Error(code: String, name: String, message: String, span: Span)
}

/// Turns a list of errors into a Document that nicely display those with
/// a tooltip that highlights the error source.
/// 
/// The text of the error message has to be flexible: fitting as much as
/// possible on a single line and breaking it when needed in order not to exceed
/// the terminal's size.
/// 
/// The developer who's writing the error messages shouldn't worry about where
/// the error messages need to be split. Their only concern is dividing the
/// error text in (possibly) multiple paragraphs. The pretty printer is free to
/// split words inside paragraphs to fit them on a single line, but it should
/// never remove a newline where explicitly put by the original error message.
/// 
/// ## Examples
/// 
/// ```gleam
/// let source_code =
///   "fn greet(message: String) -> Nil {\n  println(\"Hello\" <> message)\n}"
/// let errors = [Error(
///   "E001",
///   "Unused function",
///   "This function is unused!\nYou can safely remove it or make it public with the `pub` keyword.",
///   Span(0, 3, 7),
/// )]
///
/// errors_to_doc(source_code, errors)
/// |> doc.to_string(30)
/// |> io.println
/// 
/// // ->
/// // [ E001 ]: Unused function
/// // 1 | fn greet(message: String) -> Nil {
/// //        ┬────
/// //        ╰─ This function is
/// //           unused!
/// //           You can safely
/// //           remove it or make it
/// //           public with the
/// //           `pub` keyword.
/// ```
/// 
fn errors_to_doc(source_code: String, errors: List(Error)) -> Document {
  list.map(errors, error_to_doc(source_code, _))
  |> doc.join(with: doc.lines(2))
}

fn error_to_doc(source_code: String, error: Error) -> Document {
  let underline_size = error.span.column_end - error.span.column_start + 1
  let #(line_doc, prefix_size) = line_doc(source_code, error.span.line)

  [
    header_doc(error.code, error.name),
    doc.line,
    line_doc,
    [doc.line, message_doc(error.message, underline_size)]
    |> doc.concat
    |> doc.nest(by: error.span.column_start + prefix_size),
  ]
  |> doc.concat
}

fn header_doc(code: String, name: String) -> Document {
  ["[", code, "]:", name]
  |> string.join(with: " ")
  |> doc.from_string
}

fn line_doc(source_code: String, line_number: Int) -> #(Document, Int) {
  let source_code_lines = string.split(source_code, on: "\n")
  let assert Ok(line) = list.at(source_code_lines, line_number)
  let prefix = line_prefix(line_number)
  let prefix_size = string.length(prefix)
  #(doc.from_string(prefix <> line), prefix_size)
}

fn line_prefix(line_number: Int) -> String {
  int.to_string(line_number + 1) <> " | "
}

fn message_doc(message: String, length: Int) -> Document {
  [
    underlined_pointer(length),
    flexible_text(message)
    |> doc.nest(by: 3),
  ]
  |> doc.concat
}

fn underlined_pointer(length: Int) -> Document {
  [
    doc.from_string("┬" <> string.repeat("─", length - 1)),
    doc.line,
    doc.from_string("╰─ "),
  ]
  |> doc.concat
}

/// Turns a string into a flexible document: that is a document
/// where each whitespace in the original string is a `doc.flex_space`.
/// Original newlines are kept so that one can still have control on the
/// separation between different paragraphs.
/// 
fn flexible_text(text: String) -> Document {
  let to_flexible_line = fn(line) {
    string.split(line, on: " ")
    |> list.map(doc.from_string)
    |> doc.join(with: doc.flex_space)
    |> doc.group
  }

  string.split(text, on: "\n")
  |> list.map(to_flexible_line)
  |> doc.join(with: doc.line)
  |> doc.group
}

pub fn main() {
  let source_code =
    "fn greet(message: String) -> Nil {\n  println(\"Hello\" <> message)\n}"
  let errors = [
    Error(
      "E001",
      "Unused function",
      "This function is unused!\nYou can safely remove it or make it public with the `pub` keyword.",
      Span(0, 3, 7),
    ),
    Error(
      "E011",
      "Unknown variable",
      "The name `println` is not in scope here.\nDid you mean to use `io.println`?",
      Span(1, 2, 8),
    ),
  ]

  errors_to_doc(source_code, errors)
  |> doc.to_string(30)
  |> io.println
  // Example output: 
  //
  // [ E001 ]: Unused function
  // 1 | fn greet(message: String) -> Nil {
  //        ┬────
  //        ╰─ This function is
  //           unused!
  //           You can safely
  //           remove it or make it
  //           public with the
  //           `pub` keyword.
  // 
  // [ E011 ]: Unknown variable
  // 2 |   println("Hello" <> message)
  //       ┬──────
  //       ╰─ The name `println` is
  //          not in scope here.
  //          Did you mean to use
  //          `io.println`?
}
