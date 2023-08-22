import gleam/io
import gleam/list
import gleam/string
import gleam/string_builder.{StringBuilder}

pub fn main() {
  let join = fn(one, other) {
    case one, other {
      Empty, document | document, Empty -> document
      _, _ -> concat_all([one, soft_break(), other])
    }
  }

  let hard_join = fn(one, other) {
    case one, other {
      Empty, document | document, Empty -> document
      _, _ -> concat_all([one, hard_break(), other])
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
  |> to_string_builder(10)
  |> string_builder.to_string
  |> io.println
}

pub opaque type Document {
  Empty
  Concat(left: Document, right: Document)
  Text(text: String)
  Nest(document: Document, indentation: Int)
  Break
  Group(document: Document)
}

pub fn empty() -> Document {
  Empty
}

pub fn concat(first: Document, with second: Document) -> Document {
  Concat(first, second)
}

pub fn text(text: String) -> Document {
  Text(text)
}

pub fn nest(document: Document, by indentation: Int) -> Document {
  Nest(document, indentation)
}

pub fn break() -> Document {
  Break
}

pub fn group(document: Document) -> Document {
  Group(document)
}

pub fn concat_all(documents: List(Document)) -> Document {
  case documents {
    [first, ..rest] -> list.fold(rest, from: first, with: concat)
    [] -> Empty
  }
}

pub fn to_string_builder(document: Document, width: Int) -> StringBuilder {
  [#(0, Unbroken, document)]
  |> to_simple_document(width, 0, _)
  |> simple_document_to_string_builder()
}

type Mode {
  Broken
  Unbroken
  ForcedBroken
}

fn fits(
  width: Int,
  current_width: Int,
  documents: List(#(Int, Mode, Document)),
) -> Bool {
  case documents {
    _ if current_width < 0 -> False
    [] -> True
    [#(_, _, Empty), ..rest] -> fits(width, current_width, rest)
    [#(i, mode, Concat(one, other)), ..rest] ->
      [#(i, mode, one), #(i, mode, other), ..rest]
      |> fits(width, current_width, _)
    [#(i, mode, Nest(document, j)), ..rest] ->
      [#(i + j, mode, document), ..rest]
      |> fits(width, current_width, _)
    [#(_, _, Text(text)), ..rest] ->
      fits(width, current_width - string.length(text), rest)
    [#(_, Unbroken, Break), ..rest] -> fits(width, current_width - 1, rest)
    [#(_, Broken, Break), ..] -> True
    [#(i, _, Group(docs)), ..rest] ->
      [#(i, Unbroken, docs), ..rest]
      |> fits(width, current_width, _)
  }
}

// TODO make this tail recursive
fn to_simple_document(
  width: Int,
  consumed: Int,
  documents: List(#(Int, Mode, Document)),
) -> SimpleDocument {
  case documents {
    [] -> SimpleEmpty
    [#(_, _, Empty), ..rest] -> to_simple_document(width, consumed, rest)
    [#(i, mode, Concat(one, other)), ..rest] ->
      [#(i, mode, one), #(i, mode, other), ..rest]
      |> to_simple_document(width, consumed, _)
    [#(i, mode, Nest(document, j)), ..rest] ->
      to_simple_document(width, consumed, [#(i + j, mode, document), ..rest])
    [#(_, _, Text(text)), ..rest] ->
      to_simple_document(width, consumed + string.length(text), rest)
      |> SimpleText(text, _)
    [#(_, Unbroken, Break), ..rest] ->
      to_simple_document(width, consumed + 1, rest)
      |> SimpleText(" ", _)
    [#(i, Broken, Break), ..rest] ->
      to_simple_document(width, i, rest)
      |> SimpleLine(i, _)
    [#(i, _, Group(document)), ..rest] -> {
      let fits =
        fits(width, width - consumed, [#(i, Unbroken, document), ..rest])
      let mode = case fits {
        True -> Unbroken
        False -> Broken
      }
      io.debug(document)
      io.debug(mode)
      io.println("---------------------")
      to_simple_document(width, consumed, [#(i, mode, document), ..rest])
    }
  }
}

type SimpleDocument {
  SimpleEmpty
  SimpleText(text: String, rest: SimpleDocument)
  SimpleLine(indentation: Int, rest: SimpleDocument)
}

fn simple_document_to_string_builder(document: SimpleDocument) -> StringBuilder {
  do_simple_document_to_string_builder(document, string_builder.new())
}

fn do_simple_document_to_string_builder(
  document: SimpleDocument,
  accumulator: StringBuilder,
) -> StringBuilder {
  case document {
    SimpleEmpty -> accumulator

    SimpleText(text, rest) ->
      accumulator
      |> string_builder.append(text)
      |> do_simple_document_to_string_builder(rest, _)

    SimpleLine(indentation, rest) ->
      accumulator
      |> string_builder.append("\n")
      |> string_builder.append(string.repeat(" ", indentation))
      |> do_simple_document_to_string_builder(rest, _)
  }
}
