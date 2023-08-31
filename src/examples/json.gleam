import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import glam/doc.{Document}

type JSON {
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

/// Pretty prints a JSON object:
/// - booleans are printed as "true"/"false"
/// - strings are surrounded by quotes
/// - null is printed as "null"
/// - arrays are split on newlines only if they cannot fit on one
/// - the same applies to objects
/// - if an array/object field has to be split, its open parenthesis 
///   should still be kept on the same line as the field name
/// 
/// ## Examples
/// 
/// ```
/// let array = Array([Null, Bool(True), Bool(False)]) |> json_to_doc
/// array |> doc.to_string(40)
/// // -> [null, true, false]
/// 
/// array |> doc.to_string(10)
/// // -> [
/// //   null,
/// //   true,
/// //   false
/// // ]
/// ``` 
/// 
/// ```
/// let object =
///   Object([#("name", String("Giacomo")), #("loves_gleam", Bool(True))])
///   |> json_to_doc
/// object |> doc.to_string(80)
/// // -> { name: "Giacomo", loves_gleam: True } 
/// 
/// object |> doc.to_string(10)
/// // -> {
/// //   name: "Giacomo",
/// //   loves_gleam: True
/// // }
/// ```
///
/// ```
/// let object =
///   Object([
///     #("name", String("Giacomo")),
///     #("likes", Array([String("Gleam"), String("FP")]))
///   ])
///   |> json_to_doc
/// object |> doc.to_string(80)
/// // -> { name: "Giacomo", loves_gleam: True } 
/// 
/// object |> doc.to_string(10)
/// // -> {
/// //   name: "Giacomo",
/// //   likes: [
/// //     "Gleam",
/// //     "FP"
/// //   ]
/// // }
/// ```
/// 
fn json_to_doc(json: JSON) -> Document {
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
  |> doc.concat_join(with: [comma(), doc.space])
  |> parenthesise("[", "]")
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  list.map(fields, field_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> parenthesise("{", "}")
}

fn parenthesise(doc: Document, open: String, close: String) -> Document {
  doc
  |> doc.prepend_docs([doc.from_string(open), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string(close)])
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
  let the_sundial =
    Object([
      #("title", String("The sundial")),
      #("author", String("Shirley Jackson")),
      #("publication_year", Number(1958.0)),
      #("read", Bool(True)),
      #(
        "characters",
        Array([
          String("Mrs. Halloran"),
          String("Essex"),
          String("Captain Scarabombardon"),
        ]),
      ),
      #("average_rating", Number(5.0)),
      #(
        "ratings",
        Array([
          Object([#("from", String("Ben")), #("value", Number(5.0))]),
          Object([#("from", String("Giacomo")), #("value", Number(5.0))]),
        ]),
      ),
    ])

  use max_width <- list.each([30, 50, 80])
  io.println("Max width: " <> int.to_string(max_width))
  io.println(string.repeat("-", max_width))

  json_to_doc(the_sundial)
  |> doc.to_string(max_width)
  |> io.println
  io.println("")
}
