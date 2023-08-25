import gleam/bool
import gleam/float
import gleam/io
import gleam/list
import gleam/string
import glam/doc.{Document}

pub type JSON {
  String(String)
  Number(Float)
  Bool(Bool)
  Null
  Array(List(JSON))
  Object(List(#(String, JSON)))
}

fn colon() -> Document {
  doc.from_string(":")
}

fn comma() -> Document {
  doc.from_string(",")
}

pub fn json_to_doc(json: JSON) -> Document {
  case json {
    String(string) -> doc.from_string("\"" <> string <> "\"")
    Number(number) -> doc.from_string(float.to_string(number))
    Bool(bool) -> bool_to_doc(bool)
    Null -> doc.from_string("null")
    Array(objects) -> array_to_doc(objects)
    Object(fields) -> object_to_doc(fields)
  }
}

fn bool_to_doc(bool: Bool) -> Document {
  bool.to_string(bool)
  |> string.lowercase
  |> doc.from_string
}

fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.concat_join(with: [comma(), doc.space()])
  |> parenthesise("[", "]")
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  list.map(fields, field_to_doc)
  |> doc.concat_join(with: [comma(), doc.space()])
  |> parenthesise("{", "}")
}

fn parenthesise(doc: Document, open: String, close: String) -> Document {
  doc
  |> doc.prepend_docs([doc.from_string(open), doc.space()])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space(), doc.from_string(close)])
  |> doc.group
}

fn field_to_doc(field: #(String, JSON)) -> Document {
  let #(name, value) = field
  let name_doc = doc.from_string(name)
  let value_doc = json_to_doc(value)
  [name_doc, colon(), doc.from_string(" "), value_doc]
  |> doc.concat
}

pub fn main() {
  let width = 50
  let array = Array([Null, Null, Null, Bool(True), Bool(False)])
  let nested_object =
    Object([
      #("inner1", Number(123_123_123.1)),
      #("inner2", Number(11.0)),
      #("arrg", array),
    ])
  let object =
    Object([
      #("field1", Null),
      #("field2", array),
      #("nested", nested_object),
      #("field3", String("foo bar baz")),
    ])

  string.repeat("-", width)
  |> io.println

  json_to_doc(object)
  |> doc.to_string(width)
  |> io.println
}
