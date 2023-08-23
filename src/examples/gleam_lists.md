# Pretty printing glamorous lists ✨

This is an introductory tutorial on how to use the [glam](TODO) library to
pretty print a simple data structure.

## Setup

This tutorial is full of code examples so you can follow along with your own
Gleam project. If you have a working installation of Gleam, open your terminal
and enter the following:

```shell
gleam new glam_tutorial # create a new project named `glam_tutorial`
cd glam_tutorial        # jump into its directory
gleam add doc           # add the `doc` library to the project's dependencies
```

First things first, we can import the library in a module like this:

```gleam
import glam/doc.{Document}
```

## Goals

Before we start writing some code, let me set the scene: our goal for this
tutorial project is being able to pretty print lists of strings the same way
they get formatted by the Gleam pretty printer. There are two rules:

- If a list is shorter than the maximum line width, it is kept on a single line
- If it is longer than the maximum line width, each element is placed on a new
  line and is indented by two spaces; in addition the last element has a
  trailing comma

Since a ~~picture~~ code snippet is worth a thousand words let me show you an example:

```gleam
// ───────────────── // <- This is to show the 20 chars limit

["Hello", "Gleam"]   // <- This can stay on a single line, easy!

[                    // <- This wouldn't fit on a single line
  "Gleam",           //    so each element is split on a different   
  "is",              //    line and is indented by two spaces 
  "fun!",            // <- Notice the trailing comma!
]
```

Now that we have a clear picture of what our pretty printed lists should look
like we can dive deep into the wonders of pretty printing!

## Basic building blocks

Let's start by writing the type of the pretty printing function we need,
after all it is always a good idea to write down the types and let them guide
you!

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  todo("Write an amazing pretty printer")
}
```

The first thing you can notice is that the pretty printing function returns a
`Document` that we imported earlier from the glam library.
But wait! Weren't we supposed to pretty print the list?
Why isn't the function returning a `String`?

Here is the first crucial point of how the glam library handles pretty printing:
you can describe the structured text you want to pretty print with some basic
building blocks and the library will do the heavy lifting of trying to find the
best layout.
As you may have guessed those building blocks are of type `Document`! So as long
as we can turn a list into a document the library will pretty print it for us.
Quite neat, isn't it?

### A naive approach

First of all we need a way to create a `Document` from a `String`, luckily
glam has got us covered with the `doc.text` function which does exactly that:

```gleam
doc.text("foo bar baz")
|> doc.to_string(80)
// -> "foo bar baz"
```

Aside from `doc.text` there are a few things we need to unpack in this example:
as you can see, the function to actually pretty print a document by turning it
into a string is `doc.to_string`.
Its second parameter is the maximum line width used to figure out the best
layout for the document.

With this function in our toolbox we can now turn each of the items of the list
into documents:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }
  let docs = list.map(list, list_item_to_document)

  todo("Still not enough...")
}
```

We now have a list of documents but we need a way to join them together.
To do that we can use the `doc.concat` funtion which takes a list of documents
as input and joins them together into a single document:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }
  let docs = list.map(list, list_item_to_document)
  docs |> doc.concat
}
```

Now we can try out `pretty_list`:

```gleam
pub fn main() {
  let list = ["foo", "bar"]
  pretty_list(list)
  |> doc.to_string(80)
  |> io.println
}

// In this tutorial I'll use comments starting with "λ>" to show
// what you'd see by running that command in your terminal

// λ> gleam run
// foobar
```

Looks like we forgot to sprinkle some separating commas and square brackets here
and there, let's fix this!

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }

  list.map(list, list_item_to_document)
  |> list.intersperse(doc.text(", ")) // put a comma between each doc
  |> list.prepend(doc.text("["))      // starting open bracket
  |> list.append([doc.text("]")])     // final closing bracket
  |> doc.concat                       // join everything together
}

// λ> gleam run
// [foo, bar]
```

That's awesome! With a couple of lines of code we managed to print a list
of string, let's play a bit more with the maximum line width and see how
the list gets printed:

```gleam
pub fn main() {
  let list = ["foo", "bar"]
  pretty_list(list)
  |> doc.to_string(5) // <- this is really small and the list
  |> io.println       //    should be printed on multiple lines
}

// λ> gleam run
// [foo, bar]
```

It looks like we need a bit more than just `doc.concat` to create beautiful
documents. It's time to introduce more basic building blocks!

### A less naive approach

To understand the problem here we need to know more about the inner workings of
the pretty printer and how it handles documents joined with `doc.concat`. The
rule is quite straightforward: every document joined with `doc.concat` is
printed exactly as it is and no spaces or newlines are automatically inserted
between each document.

So we need a way to explicitly tell the pretty printer when and how it can break
groups of documents and insert newlines: this is the job for `doc.group` and
`doc.space`.

## Recap

> TODO:

---

Thanks for following along! If you spot any spelling mistake, wrong code
snippets or there are parts that are not clear, please let me know!

Your feedback really means a lot to me so don't be scared to ping me anywhere!
My Twitter handle is [@giacomo_cava](https://twitter.com/giacomo_cava) and I
usually hang around in the [Gleam Discord server](https://discord.gg/Fm8Pwmy),
so you can ping me there (I'm `jak11`)
