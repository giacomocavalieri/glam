import birdie
import glam/doc
import glam/examples/error_messages
import glam/examples/gleam_lists
import glam/examples/json
import glam/examples/todo_lists

pub fn error_messages_in_a_small_space_test() {
  error_messages.errors_to_doc(
    error_messages.example_source_code,
    error_messages.example_errors(),
  )
  |> doc.to_string(30)
  |> birdie.snap(title: "error messages in a small space")
}

pub fn error_messages_in_a_big_space_test() {
  error_messages.errors_to_doc(
    error_messages.example_source_code,
    error_messages.example_errors(),
  )
  |> doc.to_string(80)
  |> birdie.snap(title: "error messages in a big space")
}

pub fn gleam_list_in_a_big_space_test() {
  gleam_lists.pretty_list(["Gleam", "is", "fun!"])
  |> doc.to_string(23)
  |> birdie.snap(title: "gleam list in a big space")
}

pub fn gleam_list_in_a_small_space_test() {
  gleam_lists.pretty_list(["Gleam", "is", "fun!"])
  |> doc.to_string(22)
  |> birdie.snap(title: "gleam list in a small space")
}

pub fn json_in_a_big_space_test() {
  json.example_json()
  |> json.json_to_doc
  |> doc.to_string(75)
  |> birdie.snap(title: "json in a big space")
}

pub fn json_in_a_smallish_space_test() {
  json.example_json()
  |> json.json_to_doc
  |> doc.to_string(74)
  |> birdie.snap(title: "json in a small-ish space")
}

pub fn json_in_a_small_space_test() {
  json.example_json()
  |> json.json_to_doc
  |> doc.to_string(30)
  |> birdie.snap(title: "json in a small space")
}

pub fn todo_list_in_a_small_space_test() {
  todo_lists.tasks_to_doc(todo_lists.example_todo_list())
  |> doc.to_string(1)
  |> birdie.snap(title: "todo list in a small space")
}

pub fn todo_list_in_a_big_space_test() {
  todo_lists.tasks_to_doc(todo_lists.example_todo_list())
  |> doc.to_string(100_000)
  |> birdie.snap(title: "todo list in a big space")
}
