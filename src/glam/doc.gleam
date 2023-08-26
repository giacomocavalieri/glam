import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}

pub opaque type Document {
  Line(size: Int)
  Concat(docs: List(Document))
  Text(text: String)
  Nest(doc: Document, indentation: Int)
  ForceBreak(doc: Document)
  Break(broken: String, unbroken: String)
  Group(doc: Document)
}

pub const empty: Document = Concat([])

pub const line: Document = Line(1)

pub const space: Document = Break("", " ")

pub const soft_break: Document = Break("", "")

pub fn lines(size: Int) -> Document {
  Line(size)
}

pub fn concat(docs: List(Document)) -> Document {
  Concat(docs)
}

pub fn from_string(string: String) -> Document {
  Text(string)
}

pub fn nest(doc: Document, by indentation: Int) -> Document {
  Nest(doc, indentation)
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

pub fn join(docs: List(Document), with separator: Document) -> Document {
  concat(list.intersperse(docs, separator))
}

pub fn concat_join(
  docs: List(Document),
  with separators: List(Document),
) -> Document {
  join(docs, concat(separators))
}

pub fn append(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat(list.append(docs, [second]))
    _ -> Concat([first, second])
  }
}

pub fn append_docs(first: Document, docs: List(Document)) -> Document {
  append(to: first, doc: concat(docs))
}

pub fn prepend(to first: Document, doc second: Document) -> Document {
  case first {
    Concat(docs) -> Concat([second, ..docs])
    _ -> Concat([second, first])
  }
}

pub fn prepend_docs(first: Document, docs: List(Document)) -> Document {
  prepend(to: first, doc: concat(docs))
}

pub fn to_string_builder(doc: Document, width: Int) -> StringBuilder {
  do_format(string_builder.new(), width, 0, [#(0, Unbroken, doc)])
}

pub fn to_string(doc: Document, width: Int) -> String {
  to_string_builder(doc, width)
  |> string_builder.to_string()
}

type Mode {
  Broken
  ForceBroken
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
            Broken | ForceBroken -> True
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

            Broken | ForceBroken ->
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
