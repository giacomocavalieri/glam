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

pub fn empty_test() {
  doc.empty
  |> doc.to_string(10)
  |> should.equal("")

  doc.empty
  |> doc.to_string(0)
  |> should.equal("")
}

pub fn line_test() {
  doc.line
  |> doc.to_string(10)
  |> should.equal("\n")

  doc.line
  |> doc.to_string(0)
  |> should.equal("\n")
}

pub fn lines_test() {
  use n <- list.each([-1, 0, 1, 10])
  doc.lines(n)
  |> doc.to_string(10)
  |> should.equal(string.repeat("\n", n))
}
