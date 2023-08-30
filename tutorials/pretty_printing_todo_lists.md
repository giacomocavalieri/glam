# Pretty printing TODO lists

This tutorial assumes that you already have some familiarity with
pretty-printing in Glam and with its API.

If you feel like you need to brush up on your pretty-printing skills, you can
first go through the
[introductory tutorial](https://hexdocs.pm/glam/01_gleam_lists.html) and come
back to this one.

## Goals

This tutorial will show you how to write a pretty printer for TODO lists.
While doing so, you'll learn some of the remaining bits of Glam's API that
were not covered in the introductory tutorial; you'll also get more familiar
with how nesting works.

## TODO lists

First of all, let's have a look at the data structure we're going to
pretty print:

```gleam
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
```

A `TodoList` is a list of `Task`s; each task has a description, a status and
many subtasks.
Let's look at an example of such data structure _(any similarity to actual_
_persons ~~me~~ or actual events ~~me writing this tutorial~~ is purely_
_coincidental)_:

```gleam
let todo_list = [
  Task(InProgress, "publish Glam v1.1.0", [
    Task(InProgress, "write a tutorial on todo lists", []),
    Task(InProgress, "add `doc.flex_break`", [
      Task(Done, "add the appropriate type variant", []),
      Task(Done, "implement the missing cases", []),
      Task(Todo, "add some tests", []),
    ]),
  ]),
  Task(Todo, "get some sleep", []),
]
```

We want each list item to be on its own line and to be preceded by a bullet
point. Also, each list of subtasks should be indented by two spaces more than
its parent.

The TODO list I've just shown you would look like this:

```text
- […] publish Glam v1.1.0
  - […] write a tutorial on todo lists
  - […] add `doc.flex_break`
    - [X] add the appropriate type variant
    - [X] implement the missing cases
    - [ ] add some tests
- [ ] get some sleep
```

## 
