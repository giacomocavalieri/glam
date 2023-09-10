# Pretty printing TODO lists

This tutorial assumes that you already have some familiarity with
pretty printing in Glam and with its API.

If you feel like you need to brush up on your pretty printing skills, you can
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

## A mostly wrong implementation

We need to find a way to turn a `TodoList` into a `Document` so that Glam will
be able to pretty print it for us. The function we're looking for looks like
this:

```gleam
fn tasks_to_doc(tasks: TodoList) -> Document {
  todo as "Write an amazing pretty printer"
}
```

We can turn this problem into something more approachable by first tackling the
pretty printing of a single task:

```gleam
fn task_to_doc(task: Task) -> Document {
  todo as "Another amazing pretty printer"
}
```

With this definition it's quite straightforward to implement a
_mostly_ correct (more on this later) `tasks_to_doc`:

```gleam
fn tasks_to_doc(tasks: TodoList) -> Document {
  list.map(tasks, task_to_doc)
  |> doc.join(with: doc.soft_break)
}
```

### Pretty printing a task

In order to pretty print a single task, we first have to create the appropriate
bullet point according to its status:

```gleam
fn status_to_bullet(status: Status) -> String {
  case status {
    Todo -> "- [ ]"
    Done -> "- [X]"
    InProgress -> "- […]"
  }
}
```

Now we're ready to turn a task into a document:

```gleam
fn task_to_doc(task: Task) -> Document {
  let task_line = status_to_bullet(task.status) <> " " <> task.description
  let task_doc = doc.from_string(task_line)
  
  todo as "Bear with me a little longer..."
}
```

The document for the task we've just created is obtained from a single string:
if we joined the pieces with a `doc.space`, the pretty printer could split the
bullet point and the task description on different lines.
What we want is to have the task always on the same line as its bullet.

Now we can turn our attention to the list of subtasks; we can handle those with
a mutually recursive call to `tasks_to_doc`:

```gleam
fn task_to_doc(task: Task) -> Document {
  let task_line = status_to_bullet(task.status) <> " " <> task.description
  let task_doc = doc.from_string(task_line)

  case list.is_empty(tasks.subtasks) {
    True -> task_doc
    False ->
      [task_doc, doc.soft_break, docs_to_task(task.subtasks)]
      |> doc.concat
  }
}
```

We just have to be careful and remember to not add any space if there's actually
no subtask to display.
When there are subtasks, though, we join their document and the task's one with
a `doc.soft_break`.

Let's try this out and see how a TODO list is pretty printed:

```gleam
[
  Task(Todo, "groceries", [
    Task(Todo, "lentils", [])
    Task(Todo, "carrots", [])
  ])
]
|> tasks_to_doc
|> doc.to_string(10_000)
// -> - [ ] groceries- [ ] lentils- [ ] carrots
```

Looks like everything ended up on a single line. What we wanted was to get a
task per line, no matter how wide it is.

The problem is that, when the pretty printer has to deal with a `doc.soft_break`
(or any other kind of `break`), it only splits it if the group it belongs to
doesn't fit on a single line.
If, like in this example, we provide the pretty printer enough space, it will
gladly keep everything on a single line!

There is a quick and dirty solution: just trick the pretty printer and use `0`
as the maximum width.
Then, the pretty printer will always split every single group it runs into:

```gleam
[
  Task(Todo, "first", []),
  Task(Todo, "second", []),
]
|> tasks_to_doc
|> doc.to_string(0)
// ->
// - [ ] first
// - [ ] second
```

While this works for such a simple example, the problem with this approach is
that it breaks down quite easily for more complex documents: imagine you had
only a portion of the document that you wanted to always break; by setting the
line width to `0` you're going to always break _every single group_.

## Forcing a break

There's a better way to force the pretty printer to always break a given break:
`doc.force_break`.
This function takes a document as input and forces the pretty printer to break
the `doc.break` it is made of:

```gleam
let example = 
  ["first", "second"]
  |> list.map(doc.from_string)
  |> doc.join(with: doc.space)
  |> doc.force_break

doc.to_string(example, 10_000)
// ->
// first
// second
```

As you can see, despite having plenty of room to fit both `"first"` and
`"second"` on a single line, the pretty printer was forced to break the space.

There's a detail to pay attention to: `doc.force_break` _does not work on_
_groups_! The pretty printer will always try to first fit a group onto a single
line, ignoring any `doc.force_break` wrapping it:

```gleam
let example =
  ["first", "second"]
  |> list.map(doc.from_string)
  |> doc.join(with: doc.space)
  |> doc.group
  |> doc.force_break

doc.to_string(example, 10_000)
// -> first second
```

Simply wrapping everything in a `doc.group` _before_ calling `doc.force_break`
renders it useless: the pretty printer will just ignore it and treat the group
as it usually would.

### Fixing the TODO list pretty printer

We can take advantage of `doc.force_break` to ask the pretty printer to split
the items on newlines, no matter the line width.
The required change to get a correct implementation of `tasks_to_doc` is minimal:

```gleam
fn tasks_to_doc(tasks: TodoList) -> Document {
  list.map(tasks, task_to_doc)
  |> doc.join(with: doc.soft_break)
  |> doc.force_break
}
```

Simply wrapping the resulting `Document` in a `doc.force_break` is enough to
make sure the pretty printer always ends up splitting the `doc.soft_break` we
used to join the tasks.

Let's have a look at the pretty printed list now:

```gleam
[
  Task(Todo, "groceries", [
    Task(Todo, "lentils", [])
    Task(Todo, "carrots", [])
  ])
]
|> tasks_to_doc
|> doc.to_string(10_000)
// ->
// - [ ] groceries
// - [ ] lentils
// - [ ] carrots
```

Almost perfect! We just need to indent the subtasks to make this look as we
wanted.

## Nesting subtasks

As we've already seen in the introductory tutorial, we can use `doc.nest` to
increase the padding added after each newline inserted by the pretty printer.

Once again the code change to make our function work as intended is minimal:

```gleam
fn task_to_doc(task: Task) -> Document {
  let task_line = status_to_bullet(task.status) <> " " <> task.description
  let task_doc = doc.from_string(task_line)

  case list.is_empty(tasks.subtasks) {
    True -> task_doc
    False ->
      [task_doc, doc.soft_break, docs_to_task(task.subtasks)]
      |> doc.concat
      |> doc.nest(by: 2)
      // ^-- we just needed to add this single line
  }
}
```

One nice thing about `doc.nest` is that it _increases_ the nesting level of the
document. This means that, any other nesting that comes before it is
automatically increased by the same amount.
That's why this small change is enough to deal with deeply nested task lists
and each sublist is going to be nested at the right level.

If we now call `tasks_to_doc` on the TODO list I showed you at the beginning of
the tutorial what we get is this nice-looking list:

```gleam
tasks_to_doc(todo_list)
|> doc.to_string(10_000)
// ->
// - […] publish Glam v1.1.0
//   - […] write a tutorial on todo lists
//   - […] add `doc.flex_break`
//     - [X] add the appropriate type variant
//     - [X] implement the missing cases
//     - [ ] add some tests
// - [ ] get some sleep
```

## Recap

Our final implementation is just a bit less than 30 lines of pretty printing
but we got quite a nice value out of it:

- You learned about `doc.force_break` as a way to force the pretty printer
  to nicely handle break that should always be split
- Hopefully you got a better understanding of how `doc.nest` can help you
  nest arbitrarily deep data structures

If you want to take a look at the full implementation code, you can find it
[here](https://github.com/giacomocavalieri/glam/blob/main/src/examples/todo_lists.gleam).

## What to do next?

If you want to test your skills on a real-world example, you can have a look at
the
[JSON pretty printing tutorial](https://hexdocs.pm/glam/pretty_printing_JSON.html),
I highly recommend you try it: it's really rewarding and you'll never look at
online JSON formatters in the same way!

There's also another tutorial on
[pretty printing lovely error messages](https://hexdocs.pm/glam/pretty_printing_lovely_error_messages.html)
you can look at.
It's one of the tutorials I had the most fun writing, I hope you find it
interesting as well!
