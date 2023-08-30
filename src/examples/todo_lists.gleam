import gleam/io
import gleam/list
import glam/doc.{Document}

type TodoList =
  List(Task)

type Task {
  Task(status: Status, description: String, subtasks: TodoList)
}

type Status {
  Todo
  Done
  InProgress
}

/// Pretty prints a `TodoList`:
/// - each task is preceded by a bullet that indicates its status
/// - each list of subtasks is indented by 2 spaces more than its father
/// - each task should _always_ be on its own line, no matter how wide the
///   maximum line width
/// 
/// ## Examples
/// 
/// ```gleam
/// [
///   Task(Todo, "foo", []),
///   Task(InProgress, "bar", []),
///   Task(Done, "baz", []),
/// ]
/// |> tasks_to_doc
/// |> doc.to_string(10_000)
/// // ->
/// // - [ ] foo
/// // - […] bar
/// // - [X] baz
/// ```
/// 
/// ```gleam
/// [
///   Task(InProgress, "foo", [
///     Task(Done, "bar", [
///       Task(Todo, "baz", []) 
///     ])
///   ]),
/// ]
/// |> tasks_to_doc
/// |> doc.to_string(10_000)
/// // ->
/// // - […] foo
/// //   - [X] bar
/// //     - [ ] baz
/// ```
/// 
fn tasks_to_doc(tasks: TodoList) -> Document {
  list.map(tasks, task_to_doc)
  |> doc.join(with: doc.soft_break)
  |> doc.force_break
}

fn task_to_doc(task: Task) -> Document {
  let task_line = status_to_bullet(task.status) <> " " <> task.description
  let task_doc = doc.from_string(task_line)

  case list.is_empty(task.subtasks) {
    True -> task_doc
    False ->
      [doc.soft_break, tasks_to_doc(task.subtasks)]
      |> doc.concat
      |> doc.nest(by: 2)
      |> doc.prepend(task_doc)
  }
}

fn status_to_bullet(status: Status) -> String {
  case status {
    Todo -> "- [ ]"
    Done -> "- [X]"
    InProgress -> "- […]"
  }
}

pub fn main() {
  let todo_list = [
    Task(
      InProgress,
      "publish Glam v1.1.0",
      [
        Task(InProgress, "write a tutorial on todo lists", []),
        Task(
          InProgress,
          "add `doc.flex_break`",
          [
            Task(Done, "add the appropriate type variant", []),
            Task(Done, "implement the missing cases", []),
            Task(Todo, "add some tests", []),
          ],
        ),
      ],
    ),
    Task(Todo, "get some sleep", []),
  ]

  todo_list
  |> tasks_to_doc
  |> doc.to_string(10_000)
  |> io.println
}
