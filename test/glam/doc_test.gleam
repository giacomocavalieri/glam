import gleam/list
import gleam/string
import gleeunit/should
import glam/doc

pub fn append_test() {
  doc.from_string("foo")
  |> doc.append(doc.from_string("bar"))
  |> doc.to_string(80)
  |> should.equal("foobar")
}

pub fn append_docs_test() {
  doc.from_string("foo")
  |> doc.append_docs([doc.from_string("bar"), doc.from_string("baz")])
  |> doc.to_string(80)
  |> should.equal("foobarbaz")
}

pub fn break_test() {
  let message =
    [
      doc.from_string("pretty"),
      doc.break("•", "↩"),
      doc.from_string("printed"),
    ]
    |> doc.concat
    |> doc.group

  message
  |> doc.to_string(20)
  |> should.equal("pretty•printed")

  message
  |> doc.to_string(10)
  |> should.equal("pretty↩\nprinted")
}

pub fn concat_test() {
  ["pretty", " ", "printed"]
  |> list.map(doc.from_string)
  |> doc.concat
  |> doc.to_string(80)
  |> should.equal("pretty printed")
}

pub fn concat_join_test() {
  let separators = [doc.from_string(","), doc.space]
  let docs =
    ["wow", "so", "many", "commas"]
    |> list.map(doc.from_string)

  doc.concat_join(docs, separators)
  |> should.equal(doc.join(docs, doc.concat(separators)))
}

pub fn force_break_test() {
  [
    doc.from_string("pretty"),
    doc.break("•", "↩"),
    doc.from_string("printed"),
  ]
  |> doc.concat
  |> doc.force_break
  |> doc.group
  |> doc.to_string(100)
  |> should.equal("pretty↩\nprinted")
}

pub fn group_test() {
  let food =
    ["lasagna", "ravioli", "pizza"]
    |> list.map(doc.from_string)
    |> doc.join(with: doc.space)
    |> doc.group

  let message =
    [doc.from_string("Food I love:"), doc.space, food]
    |> doc.concat
    |> doc.group

  doc.to_string(message, 80)
  |> should.equal("Food I love: lasagna ravioli pizza")
  doc.to_string(message, 30)
  |> should.equal("Food I love:\nlasagna ravioli pizza")
  doc.to_string(message, 20)
  |> should.equal("Food I love:\nlasagna\nravioli\npizza")
}

pub fn join_test() {
  let message =
    ["Gleam", "is", "fun!"]
    |> list.map(doc.from_string)
    |> doc.join(with: doc.space)

  doc.to_string(message, 80)
  |> should.equal("Gleam is fun!")
}

pub fn lines_test() {
  use n <- list.each([-1, 0, 1, 10])
  doc.lines(n)
  |> doc.to_string(10)
  |> should.equal(string.repeat("\n", n))
}

pub fn nest_test() {
  let one =
    [doc.space, doc.from_string("one")]
    |> doc.concat
    |> doc.nest(by: 1)

  let two =
    [doc.space, doc.from_string("two")]
    |> doc.concat
    |> doc.nest(by: 2)

  let three =
    [doc.space, doc.from_string("three")]
    |> doc.concat
    |> doc.nest(by: 3)

  let list =
    [doc.from_string("list:"), one, two, three]
    |> doc.concat
    |> doc.group

  doc.to_string(list, 10)
  |> should.equal("list:\n one\n  two\n   three")
}

pub fn prepend_test() {
  doc.from_string("printed!")
  |> doc.prepend(doc.from_string("pretty "))
  |> doc.to_string(80)
  |> should.equal("pretty printed!")
}

pub fn prepend_docs_test() {
  doc.from_string("fun!")
  |> doc.prepend_docs([doc.from_string("Gleam "), doc.from_string("is ")])
  |> doc.to_string(80)
  |> should.equal("Gleam is fun!")
}
