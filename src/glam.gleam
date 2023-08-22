import gleam/io
import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}

pub fn main() {
  let list_name = "message"
  let declaration = text("let " <> list_name <> " =")
  let list_body =
    [text("\"Gleam\""), text("\"is\"")]
    |> list.flat_map(fn(item) { [item, text(","), space()] })
    |> list.append([text("\"fun!\"")])
    |> concat_group

  let list =
    [
      text("["),
      prepend(space(), to: list_body)
      |> nest(by: 2),
      break(",", " "),
      text("]"),
    ]
    |> concat_group

  let doc =
    [declaration, space(), list]
    |> nest_group(by: 2)

  use size <- list.each([20, 30, 50])
  io.println(" Available space")
  io.println(string.repeat("-", size))

  doc
  |> format(size)
  |> string_builder.to_string
  |> io.println

  io.println("\n\n")
}

pub opaque type Document {
  Line(size: Int)
  Concat(docs: List(Document))
  Text(text: String)
  Nest(doc: Document, indentation: Int)
  ForceBreak(doc: Document)
  Break(broken: String, unbroken: String)
  Group(doc: Document)
}

pub fn empty() -> Document {
  Concat([])
}

pub fn line() -> Document {
  Line(1)
}

pub fn lines(size: Int) -> Document {
  Line(size)
}

pub fn concat(docs: List(Document)) -> Document {
  Concat(docs)
}

pub fn text(text: String) -> Document {
  Text(text)
}

pub fn nest(doc: Document, by indentation: Int) -> Document {
  Nest(doc, indentation)
}

pub fn space() -> Document {
  Break("", " ")
}

pub fn break(broken: String, unbroken: String) {
  Break(broken, unbroken)
}

pub fn group(doc: Document) -> Document {
  Group(doc)
}

pub fn force_break(doc: Document) -> Document {
  ForceBreak(doc)
}

pub fn concat_group(docs: List(Document)) -> Document {
  group(concat(docs))
}

pub fn nest_group(docs: List(Document), by indentation: Int) -> Document {
  concat_group(docs)
  |> nest(by: indentation)
}

pub fn join(docs: List(Document), with separator: Document) -> Document {
  concat(list.intersperse(docs, separator))
}

pub fn append(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat(list.append(docs, [second]))
    _ -> Concat([first, second])
  }
}

pub fn prepend(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat([second, ..docs])
    _ -> Concat([second, first])
  }
}

pub fn surround(doc: Document, open: Document, closed: Document) -> Document {
  closed
  |> prepend(doc)
  |> prepend(open)
}

pub fn format(doc: Document, width: Int) -> StringBuilder {
  do_format(string_builder.new(), width, 0, [#(0, Unbroken, doc)])
}

type Mode {
  Broken
  Unbroken
}

fn fits(
  docs: List(#(Int, Mode, Document)),
  max_width: Int,
  current_width: Int,
) -> Bool {
  case docs {
    _ if current_width > max_width -> False

    [] -> True

    [#(indent, mode, doc), ..rest] ->
      case doc {
        Line(..) -> True

        ForceBreak(..) -> False

        Text(text) -> fits(rest, max_width, current_width + string.length(text))

        Nest(doc, i) ->
          [#(indent + i, mode, doc), ..rest]
          |> fits(max_width, current_width)

        Break(unbroken: unbroken, ..) ->
          case mode {
            Broken -> True
            Unbroken ->
              fits(rest, max_width, current_width + string.length(unbroken))
          }

        Group(doc) ->
          fits([#(indent, mode, doc), ..rest], max_width, current_width)

        Concat(docs) ->
          list.map(docs, fn(doc) { #(indent, mode, doc) })
          |> list.append(rest)
          |> fits(max_width, current_width)
      }
  }
}

fn indentation(size: Int) -> String {
  string.repeat(" ", size)
}

fn do_format(
  acc: StringBuilder,
  max_width: Int,
  current_width: Int,
  docs: List(#(Int, Mode, Document)),
) -> StringBuilder {
  case docs {
    [] -> acc

    [#(indent, mode, doc), ..rest] ->
      case doc {
        Line(size) ->
          string_builder.append(acc, string.repeat("\n", size))
          |> string_builder.append(indentation(indent))
          |> do_format(max_width, indent, rest)

        Break(unbroken: unbroken, broken: broken) ->
          case mode {
            Unbroken -> {
              let new_width = current_width + string.length(unbroken)
              string_builder.append(acc, unbroken)
              |> do_format(max_width, new_width, rest)
            }

            Broken ->
              string_builder.append(acc, broken)
              |> string_builder.append("\n")
              |> string_builder.append(indentation(indent))
              |> do_format(max_width, indent, rest)
          }

        ForceBreak(doc) ->
          [#(indent, Broken, doc)]
          |> do_format(acc, max_width, current_width, _)

        Concat(docs) ->
          list.map(docs, fn(doc) { #(indent, mode, doc) })
          |> list.append(rest)
          |> do_format(acc, max_width, current_width, _)

        Group(doc) ->
          case fits([#(indent, Unbroken, doc)], max_width, current_width) {
            True -> #(indent, Unbroken, doc)
            False -> #(indent, Broken, doc)
          }
          |> list.prepend(to: rest)
          |> do_format(acc, max_width, current_width, _)

        Nest(doc, i) ->
          [#(indent + i, mode, doc), ..rest]
          |> do_format(acc, max_width, current_width, _)

        Text(text) ->
          string_builder.append(acc, text)
          |> do_format(max_width, current_width + string.length(text), rest)
      }
  }
}
