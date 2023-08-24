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

First things first, you can import the library in a your project's modules like
this:

```gleam
import glam/doc.{Document}
```

## Goals

Our goal for this tutorial project is being able to pretty print lists of
strings the same way they get formatted by the Gleam pretty printer.
There are two straightforward rules:

- If a list is shorter than the maximum line width, it is kept on a single line
- If it is longer than the maximum line width, each element is placed on a new
  line and is indented by two spaces; in addition the last element has a
  trailing comma

Since a ~~picture~~ code snippet is worth a thousand words let me show you an
example:

```gleam
// ───────────────── // <- This is to show the 20 chars limit

["Hello", "Gleam"]   // <- This can stay on a single line, easy!

[                    // <- This wouldn't fit on a single line
  "Gleam",           //    so each element is split on a different   
  "is",              //    line and is indented by two spaces 
  "fun!",            // <- Notice the trailing comma!
]
```

Now that you have a clear picture of what a pretty printed lists should look
like we can dive deep into the wonders of pretty printing!

## Basic building blocks

Let's start by writing the type of the function that can turn lists into pretty
printed lists, after all it is always a good idea to write down the types and
let them guide you.

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  todo("Write an amazing pretty printer")
}
```

The first thing you can notice is that the pretty printing function's return
type is `Document`. But wait, weren't we supposed to pretty print the list?
Why isn't the function returning a `String`?

Here is a crucial point of how the glam library handles pretty printing:
you can _describe_ the structure of the text to pretty print with some basic
building blocks and the library will do the heavy lifting of trying to find the
best layout.
As you may have guessed those building blocks are of type `Document`. As long
as you can turn something into a `Document` the library will pretty print it
for you. Quite neat, isn't it?

### A naive approach

First of all, there should be a way to create a `Document` from a `String`,
luckily glam has got us covered with the `doc.text` function which does exactly
that:

```gleam
doc.text("foo bar baz")
|> doc.to_string(80)
// -> "foo bar baz"
```

Aside from `doc.text` there are a few things to unpack in this example:
as you can see, the function to actually pretty print a document by turning it
into a string is `doc.to_string`.
Its second parameter is the maximum line width used to figure out the best
layout for the document.

With this function in your toolbox you can now turn each of the items of the
list into documents:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }
  let docs = list.map(list, list_item_to_document)

  todo("Still not enough...")
}
```

`docs` is a list of documents but in order to be printed with `doc.to_string`
it needs to be turned into a single `Document`.
To do that you can use the `doc.concat` funtion which takes a list of documents
as input and joins them together into a single document:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }
  let docs = list.map(list, list_item_to_document)
  docs |> doc.concat
}
```

`pretty_list` is now ready to be used:

```gleam
pub fn main() {
  let list = ["foo", "bar"]
  pretty_list(list)
  |> doc.to_string(80)
  |> io.println
}

// main()
// -> "foobar"
```

Not quite list-looking but we're getting there, adding commas and brackets can
be done with some standard library functions on lists:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.text(item) }

  list.map(list, list_item_to_document)
  |> list.intersperse(doc.text(", ")) // put a comma between each doc
  |> list.prepend(doc.text("["))      // starting open bracket
  |> list.append([doc.text("]")])     // final closing bracket
  |> doc.concat                       // join everything together
}

// main()
// -> "[foo, bar]"
```

Awesome, with a couple of lines of code you can now pretty print a list of
strings.
Let's play a bit more with the maximum line width and see how the list gets
printed:

```gleam
pub fn main() {
  let list = ["foo", "bar"]
  pretty_list(list)
  |> doc.to_string(5) // <- this is really small and the list
  |> io.println       //    should be printed on multiple lines
}

// main()
// -> [foo, bar]
```

It looks like `doc.concat` is not enough to create beautiful documents. In the
next section I'll introduce more building blocks that can really help to get
nice looking lists.

### A less naive approach

To understand the problem here I need to get into a bit more detail on how the
pretty printing of documents works for the blocks introduced so far:

- when the pretty printer has to display a `doc.text` it simply outputs
  the string passed to it as an argument leaving it unchanged
- when the pretty printer has to display a list of documents joined with
  `doc.concat` is formats each one and joins them together without adding any
  whitespace or trying to split them to fit on a line

> If you already have some experience in Gleam you may have noticed that
> a pretty printer that only has these two primitives is just a more convoluted
> way of concatenating strings, `doc.concat` would act as a
> `list.fold(strings, from: "", with: fn(acc, string) { acc <> string })`
>
> If this `fold` thing looks like gibberish to you, don't worry!
> You can look at
> [Gleam's Exercism track](https://exercism.org/tracks/gleam/concepts), it's a
> great way to get started and make some practice

> TODO: riparti da qui

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
