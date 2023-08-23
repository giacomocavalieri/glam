import gleam/io
import gleam/list
import gleam/string
import gleam/string_builder
import glam/doc.{Document}
// pub fn naive_pretty_list(list: List(String)) -> Document {
//   let list_item_to_document = fn(item) { doc.text(item) }
// 
//   list.map(list, list_item_to_document)
//   |> list.intersperse(doc.text(", "))
//   |> list.prepend(doc.text("["))
//   |> list.append([doc.text("]")])
//   |> doc.concat
// }

// fn list_to_doc(list: List(String)) -> Document {
//   todo
// }
// 
// pub fn main() {
//   let list_name = "message"
//   let declaration = doc.text("let " <> list_name <> " =")
//   let list_body =
//     [doc.text("\"Gleam\""), doc.text("\"is\"")]
//     |> list.flat_map(fn(item) { [item, doc.text(","), doc.space()] })
//     |> list.append([doc.text("\"fun!\"")])
//     |> doc.concat_group
// 
//   let list =
//     [
//       doc.text("["),
//       doc.prepend(doc.space(), to: list_body)
//       |> doc.nest(by: 2),
//       doc.break(",", " "),
//       doc.text("]"),
//     ]
//     |> doc.concat_group
// 
//   let doc =
//     [declaration, doc.space(), list]
//     |> doc.nest_group(by: 2)
// 
//   use size <- list.each([5])
//   io.println(" Available space")
//   io.println(string.repeat("-", size))
// 
//   let doc =
//     ["foo", "bar"]
//     |> naive_pretty_list
// 
//   doc
//   |> doc.format(size)
//   |> string_builder.to_string
//   |> io.println
// 
//   io.println("\n\n")
// }
