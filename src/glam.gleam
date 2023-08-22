import gleam/io
import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}

pub fn main() {
  let join = fn(one, other) {
    case one, other {
      Empty, doc | doc, Empty -> doc
      _, _ -> concat([one, break(), other])
    }
  }

  let hard_join = fn(one, other) {
    case one, other {
      Empty, doc | doc, Empty -> doc
      _, _ -> concat([one, line(), other])
    }
  }

  let binop = fn(left, op, right) {
    join(text(left), text(op))
    |> group
    |> join(text(right))
    |> nest(by: 2)
    |> group
  }

  let if_then_else = fn(cond, then, else) {
    let cond = group(nest(join(text("if"), cond), by: 2))
    let then = group(nest(join(text("then"), then), by: 2))
    let else = group(nest(join(text("else"), else), by: 2))
    group(hard_join(hard_join(cond, then), else))
  }

  let cond = binop("a", "==", "b")
  let expr1 = binop("a", "<<", "2")
  let expr2 = binop("a", "+", "b")
  let doc = if_then_else(cond, expr1, expr2)

  doc
  |> to_string_builder(11)
  |> string_builder.to_string
  |> io.println
}

pub opaque type Document {
  Empty
  Line
  Concat(docs: List(Document))
  Text(text: String)
  Nest(doc: Document, indentation: Int)
  Break
  Group(doc: Document)
}

pub fn empty() -> Document {
  Empty
}

pub fn line() -> Document {
  Line
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

pub fn break() -> Document {
  Break
}

pub fn group(doc: Document) -> Document {
  Group(doc)
}

pub fn to_string_builder(doc: Document, width: Int) -> StringBuilder {
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
        Empty -> fits(rest, max_width, current_width)

        Line -> True

        Text(text) -> fits(rest, max_width, current_width + string.length(text))

        Nest(doc, i) ->
          [#(indent + i, mode, doc), ..rest]
          |> fits(max_width, current_width)

        Break ->
          case mode {
            Broken -> True
            Unbroken -> fits(rest, max_width, current_width + 1)
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
        Empty -> do_format(acc, max_width, current_width, rest)

        Line ->
          string_builder.append(acc, "\n")
          |> string_builder.append(indentation(indent))
          |> do_format(max_width, indent, rest)

        Break ->
          case mode {
            Broken ->
              string_builder.append(acc, "\n")
              |> string_builder.append(indentation(indent))
              |> do_format(max_width, indent, rest)
            Unbroken ->
              string_builder.append(acc, " ")
              |> do_format(max_width, current_width + 1, rest)
          }

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
