# Pretty printing glamorous lists ✨

## Goals

The goal of this tutorial is to get you started on pretty printing with the
glam package introducing its API a step at a time.

As a running example we're going to write a pretty printer for lists of strings,
there are two here are two straightforward rules we want our pretty printer to
follow:

- If a list is shorter than the maximum allowed line width, it is kept on
  a single line
- If it is longer than the maximum line width, each element is placed on a new
  line and is indented by two spaces; in addition the last element has a
  trailing comma
- All strings are surrounded by `"`

Since a ~~picture~~ code snippet is worth a thousand words let me show you an
example:

```gleam
// ----------------- // <- This is to show the 20 chars limit

["Hello", "Gleam"]   // <- This can stay on a single line, easy!

[                    // <- This wouldn't fit on a single line
  "Gleam",           //    so each element is split on a different   
  "is",              //    line and is indented by two spaces 
  "fun!",            // <- Notice the trailing comma!
]
```

Now that we have a clear picture of what a pretty printed lists should look
like we can dive deep into the wonders of pretty printing!

## Setup

This tutorial is full of code examples so you can follow along with your own
Gleam project. If you have a working installation of Gleam, open your terminal
and enter the following:

```shell
gleam new glam_tutorial # create a new project named `glam_tutorial`
cd glam_tutorial        # jump into its directory
gleam add glam          # add the `glam` package to the project's dependencies
```

> If you know nothing about Gleam and somehow ended up here, I can recommend you
> to first check out the
> [Gleam's Exercism track]((https://exercism.org/tracks/gleam/concepts)).
> It's a great resource to get started!

First things first, you can import the glam package in your project's
modules like this:

```gleam
import glam/doc.{Document}
```

## Basic building blocks

Let's start by writing the type of the function that can turn lists into pretty
printed lists, after all it is always a good idea to write down the types and
let them guide you:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  todo("Write an amazing pretty printer")
}
```

The first thing you can notice is that the pretty printing function's return
type is `Document`. But wait, weren't we supposed to pretty print the list?
Why isn't the function returning a `String`?

Here is a crucial point of how the glam package handles pretty printing:
you can _describe_ the structure of the text to pretty print with some basic
building blocks, and glam will do the heavy lifting of trying to find the
best layout for you.
As you may have guessed those building blocks are `Document`s. As long
as you can turn something into a `Document`, glam will pretty print it for you.
Quite neat, isn't it?

### A naive approach

First of all, we need a way to create a `Document` from a `String`,
luckily glam has got us covered with the `doc.from_string` function which does
exactly that:

```gleam
doc.from_string("Hello, world!")
|> doc.to_string(80)
// -> Hello, world!
```

There are a few things to unpack in this example:

- `doc.from_string` takes a string and turns it into a `Document`
- `doc.to_string` does the opposite: given a maximum line width and a document,
  it turns it into a pretty printed string. Later we will discover how the
  maximum line width can influence the pretty printing process

With `doc.from_string` in our toolbox we can now turn each of the items of the
list into documents:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let docs = list.map(list, list_item_to_document)

  todo("Still not enough...")
}
```

`docs` is a list of documents but in order to be printed with `doc.to_string`
it needs to be turned into a single `Document`.
To do that we can use the `doc.concat` funtion which takes a list of documents
as input and joins them together into a single document:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string(item) }
  let docs = list.map(list, list_item_to_document)
  docs |> doc.concat
}
```

We're now ready to try `pretty_list`:

```gleam
["Hello", "world!"]
|> pretty_list
|> doc.to_string(80)
// -> "Hello""world!"
```

Not quite list-looking but we're getting there... adding commas and brackets can
be done with some standard library functions on lists:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }

  list.map(list, list_item_to_document)
  |> list.intersperse(doc.from_string(", ")) // put a comma between each doc
  |> list.prepend(doc.from_string("["))      // starting open bracket
  |> list.append([doc.from_string("]")])     // final closing bracket
  |> doc.concat                              // join everything together
}
```

```gleam
["Hello", "world!"]
|> pretty_list
|> doc.to_string(80)
// -> ["Hello", "world!"]
```

Awesome, with a couple of lines of code you can now pretty print a list of
strings.
Let's play a bit more with the maximum line width and see how the list gets
printed:

```gleam
pub fn main() {
  let list = ["Hello", "world!"]
  pretty_list(list)
  |> doc.to_string(5) // <- this is really small and the list
  |> io.println       //    should be printed on multiple lines
}

// main()
// -> ["Hello", "world!"]
```

We would expect the list to be split on multiple lines like in the example I
showed you at the beginning of the tutorial.
It looks like `doc.concat` is not enough to create beautiful documents. In the
next section we'll discover more building blocks that can get us closer to a
pretty printed list.

### A less naive approach

To understand the problem here we need to get into a bit more detail on how the
pretty printing of documents works:

- when the pretty printer has to display a `doc.from_string` it simply outputs
  the string passed to it as an argument leaving it unchanged
- when the pretty printer has to display a list of documents joined with
  `doc.concat`, it formats each document one and joins them together without
  adding any whitespace or trying to split them to fit on a line

> If you already have some experience in Gleam and functional programming
> you may have noticed that a pretty printer that only has these two primitives
> is just a more convoluted way of concatenating strings, `doc.concat` would act
> as a `list.fold(strings, from: "", with: fn(acc, string) { acc <> string })`
>
> If this `fold` thing looks like gibberish to you, don't worry!
> You can look at the
> [Gleam's Exercism track](https://exercism.org/tracks/gleam/concepts), it's a
> great way to get started and hone your functional programming skills! (At
> this point I'm sure you get how much I love Gleam's Exercism track)

#### Grouping docs

What we really need is a way to explicitly tell the pretty printer it is
allowed to break a document if it does not fit on a single line.

This is the job for `doc.group` and `doc.space`:

- when the pretty printer runs into a `doc.group` it first tries to render the
  document on a single line, just like `doc.concat`. The catch is that if the
  document would not fit on a single line, the pretty printer will break all the
  spaces inside it
- a `doc.space` is a special kind of document that gets normally rendered as a
  single whitespace: `" "`. However, the pretty printer can turn these spaces
  into newlines in order to split a `doc.group` that would not fit on a single
  line

Let's look at an example to make things clearer:

```gleam
let doc =
  [doc.from_string("Hello"), doc.space, doc.from_string("world!")]
  |> doc.concat
  |> doc.group

doc.to_string(doc, 80)
// -> Hello world!
doc.to_string(doc, 10)
// ->
// Hello
// world!
```

As you can see, in the second example, where the line width wouldn't allow
`"Hello"` and `"world!"` to fit onto a single line, the space is rendered as a
newline.

#### Even more examples

Before going back to our list pretty printer we should experiment a little bit
more with `doc.group` and `doc.space`.

In particular there's a little detail I omitted in my first explanation of how
group formatting works. Let's see how the pretty printer deals with nested
groups:

```gleam
let food =
  ["lasagna", "ravioli", "pizza"]
  |> list.map(doc.from_string)
  |> list.intersperse(with: doc.space)
  |> doc.concat
  |> doc.group

let food_i_love =
  // Sorry for being stereotypically italian
  [doc.from_string("Food I love:"), doc.space, food]
  |> doc.concat
  |> doc.group
```

> You'll find out that we frequently need to do something like this to join
> documents together using a custom separator:
>
> ```gleam
> list_of_docs
> |> list.intersperse(with: some_separator)
> |> doc.concat
> ```
>
> To make things a bit easier to read you can also use the `doc.join` function
> which is a shorthand for an `intersperse` followed by `concat`:
>
> ```gleam
> list_of_docs
> |> doc.join(with: some_separator)
> ```

Here we have two groups, one inside the other, let's play around with the
maximum line width and see how this gets printed:

```gleam
food_i_love |> doc.to_string(80)
// -> Food I love: lasagna ravioli pizza

food_i_love |> doc.to_string(20)
// ->
// Food I love:
// lasagna
// ravioli
// pizza

food_i_love |> doc.to_string(30)
// ->
// Food I love:
// lasagna ravioli pizza
```

- In the first example we gave the document enough space to fit on a single
  line, all spaces get rendered as a normal whitespace and everything ends up on
  a single line
- In the second example the line width is quite small: neither the outer, nor
  the inner document could fit on a single line so all spaces become newlines
- The most interesting example is the third one where the outer group is split
  while the inner is not.
  What end up happening in the pretty process could be described like this:
  - The pretty printer first tries to render everything on a single line but
    the resulting document would exceed the maximum width of 30 chars
  - So it decides to split the outer group and its space gets rendered as a
    newline
  - On the new line the pretty printer tries to render the inner document
    and it fits just right! So it's spaces, contrary to what happened to those
    of the outer group, are not turned into newlines

So when the pretty printer ends up breaking a group it may still not break the
inner groups it's composed of. Each subgroup is considered _separately_.

> It can get some time to wrap your head around how groups can influence the
> pretty printing process.
> If you want to test your understanding of `doc.group`, try to look at this
> example and guess how it will get printed at different line widths:
>
> ```gleam
> let abcd =
>   ["a", "b", "c", "d"]
>   |> list.map(doc.from_string)
>   |> doc.join(with: doc.space)
>   |> doc.group
>
> let efgh =
>   ["e", "f", "g", "h"]
>   |> list.map(doc.from_string)
>   |> doc.join(with: doc.space)
>   |> doc.group
>
> let doc =
>   [doc.from_string("some letters:"), abcd, efgh]
>   |> doc.join(with: doc.space)
>   |> doc.group
>
> // Try different widths and guess what the document will look like
> doc |> doc.to_string(...) 
> ```

#### Back onto lists

It shouldn't be too hard to update the previous iteration of `pretty_list` to
take advantage of groups and breakable spaces. Let's try it out:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let comma = doc.concat([doc.from_string(","), doc.space])
  let open_square = doc.concat([doc.from_string("["), doc.space])
  let close_square = doc.concat([doc.space, doc.from_string("]")])

  list.map(list, list_item_to_document)
  |> doc.join(with: comma)
  |> doc.prepend(open_square)
  |> doc.append(close_square)
  |> doc.group
  // ^-- Don't forget the group, otherwise the pretty
  //     printer won't be able to split on spaces
}
```

The main difference is that the comma that we use as a separator is now followed
by a `doc.space` which the pretty printer can break if the list is too long and
does now fit on a single line. The same goes for square brackets: the open
bracket is followed by a `doc.space` so that, if the document gets broken, the
list's first item will end up on a new line. Likewise, the closed bracket is
preceded by a space so that it can end up on its own line:

```gleam
pretty_list(["Gleam", "is", "fun!"]) |> doc.to_string(80)
// -> [ "Gleam", "is", "fun!" ]

pretty_list(["Gleam", "is", "fun!"]) |> doc.to_string(10)
// ->
// [
// "Gleam",
// "is",
// "fun"  
// ]
```

We're getting there! There's just a couple of things we need to fix before
calling it a day:

- The list items should be indented by two spaces
- When the list is rendered on multiple lines, the last item should have a
  trailing comma
- When the list is rendered on a single line we do not want the first and last
  items to be separated with a space from the brackets

## Nesting things

To solve the first problem, we need to add a some nesting whitespace whenever
a space is turned into a newline. In order to do so we can use the `doc.nest`
function:

```gleam
doc.nest(my_document, by: 2)
```

This tells the pretty printer that, whenever it renders a space as a newline
when formatting `my_document` it sould also indent it by two spaces.
Let's get back to the `food_i_love` example and see how the rendering changes
by adding a nesting of two spaces:

```gleam
food_i_love
|> doc.nest(by: 2)
|> doc.to_string(20)

// ->
// Food I love:
//   lasagna
//   ravioli
//   pizza
```

> If you want a more in-depth tutorial on how nesting works you can loot at the
> [todo-list tutorial](TODO:) which shows an in-depth example that is more
> focused on groups and nesting

Now we can add nesting to the `pretty_list` document:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let comma = doc.concat([doc.from_string(","), doc.space])
  let open_square = doc.concat([doc.from_string("["), doc.space])
  let close_square = doc.concat([doc.space, doc.from_string("]")])

  list.map(list, list_item_to_document)
  |> doc.join(with: comma)
  |> doc.prepend(open_square)
  |> doc.nest(by: 2)
  // ^-- every space before the final bracket will get indented
  //     by two spaces if turned into a new line
  |> doc.append(close_square)
  |> doc.group
}
```

Notice how the indentation applies to all the spaces _except_ the one that comes
before the closed square bracket. This way, the closed square bracket will not
be indented and kept on the same nesting level as the corresponding open
bracket:

```gleam
pretty_list(["Gleam", "is", "fun!"]) |> doc.to_string(10)
// ->
// [
//   "Gleam",
//   "is",
//   "fun"
// ]
```

## Custom breaks

The last piece of work we need to do to get the desired look for a pretty
printed list is adding a trailing comma and removing whitespace before and
after the square brackets:

```gleam
// This:
["Gleam", "is", "fun!"]

// not this:
[ "Gleam", "is", "fun!" ]
```

```gleam
// This:
[
  "Gleam",
  "is",
  "fun!",
]

// not this:
[
  "Gleam",
  "is",
  "fun!"
]
```

Both problema can be solved by introducing a new powerful document constructor:
`doc.break`.

Up until now `doc.space` was the only document that the pretty printer could
turn into a newline when splitting a group. Turns out that `doc.break` is a
more general version of `doc.space`. Here is how it can be called:

```gleam
doc.break("broken", "unbroken")
```

- It's first argument is the string that will be displayed if the pretty printer
  decides to break the document _before_ inserting a newline
- It's second argument is the string that will be displayed if the pretty
  printer decides not to break the document

### The pretty printing algorithm

This description of `doc.break` may sound a bit hand wavy so, to clear things
up, let's have a final look at how the formatting of documents actually works:

- The pretty printer always tries to put a group onto a single line by treating
  every `doc.break` as if it were its second argument
- If the group exceeds the maximum line width then all its `break`s are rendered
  as their first argument and immediately followed by a newline
  - If the document is also nested, the pretty printer adds a nesting of the
    given level after the newline
- After breaking the outermost group, the pretty printer considers every nested
 group on its own, deciding once again if it can fit on the new line or not

Let's look at an example:

```gleam
let visible_space = doc.break("↩", "•")
let doc =
  ["Gleam", "is", "fun!"]
  |> doc.join(with: visible_space)
  |> dog.group

doc |> doc.to_string(80)
// -> Gleam•is•fun!

doc |> doc.to_string(10)
// ->
// Gleam↩
// is↩
// fun
```

As you can see, when the pretty printer decides to split the document, all of
its breaks are displayed as `"↩"`; if it is not broken they are displayed as
`"•"`.

> `doc.space` can actually be defined in terms of `doc.break` (and that's how
> it is defined in glam!) as `doc.break("", " ")`:
>
> - if the group is not broken we render a single whitespace
> - if the group gets broken we do not render anything and let the pretty
>   printer do its magic and add a newline after each space

### Back to lists one last time

Thanks to break we can solve both our remaining problems: first of all we want
to disaply a trailing comma after the last element _only if_ the list is split
onto multiple lines:

```gleam
let trailing_comma = break(",", "")
```

This comma will only be displayed if the group it belongs to is broken by the
pretty printer:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let comma = doc.concat([doc.from_string(","), doc.space])
  let open_square = doc.concat([doc.from_string("["), doc.space])
  let trailing_comma = break(",", "")
  let close_square = doc.concat([trailing_comma, doc.from_string("]")])
  // ^-- we add the trailing comma right before the closing bracket

  list.map(list, list_item_to_document)
  |> doc.join(with: comma)
  |> doc.prepend(open_square)
  |> doc.nest(by: 2)
  |> doc.append(close_square)
  |> doc.group
}
```

As a finishing touch we need to remove the whitespace that gets printed after
the open bracket. The perfect fit for this job is once again `doc.break`:

```gleam
let soft_break = doc.break("", "")
```

`soft_break` will never be rendered, it's only purpose it to act as a possible
breaking point for the pretty printer to split a group on multiple lines.

Since `soft_break` can be useful in a lot of different settings, the glam
package already exposes it as a constant so that you do not have to redefine it
every time you need it:

```gleam
pub fn pretty_list(list: List(String)) -> Document {
  let list_item_to_document = fn(item) { doc.from_string("\"" <> item <> "\"") }
  let comma = doc.concat([doc.from_string(","), doc.space])
  let open_square = doc.concat([doc.from_string("["), doc.soft_break])
  // ^-- so that there won't be a whitespace after the open bracket
  //     but the pretty printer can still split it
  let trailing_comma = doc.break(",", "")
  let close_square = doc.concat([trailing_comma, doc.from_string("]")])

  list.map(list, list_item_to_document)
  |> doc.join(with: comma)
  |> doc.prepend(open_square)
  |> doc.nest(by: 2)
  |> doc.append(close_square)
  |> doc.group
}
```

And that's it, the pretty printer is complete!

## Recap

Phew! That was quite a long tutorial so give yourself a pat in the back and
enjoy the beautifully pretty printed lists.

We covered most of the glam API and got an understanding of how each piece can
influence the pretty printing process:

- `doc.from_string` to generate documents from strings
- `doc.concat` to join together bunch of documents
- `doc.group` and `doc.space` to allow the pretty printer to split documents
- `doc.nest` to nest documents when the pretty printer decides to split them
- `doc.break` to conditionally render strings depending if their group gets
  splitted or not

We've also used some utility methods like:

- `doc.join` which is equivalent to interspersing and then using `doc.concat`
- `doc.prepend` to prepend a document to an existing one
- `doc.append` to append a document to an existing one

But there's still a lot more to discover if you're interested in pretty
printing and want to tackle bigger, more complex problems!
You can look into the [JSON pretty printing example](TODO) or the
[todo list pretty printing example](TODO) to get a deeper understanding of
nesting and find out about other nice utility methods the package has to offer.

---

Thanks for following along! If you spot any spelling mistake, wrong code
snippets or there are parts that are not clear, please let me know!

Your feedback really means a lot to me so don't be scared to reach out!
My Twitter handle is [@giacomo_cava](https://twitter.com/giacomo_cava) and I
usually hang around in the [Gleam Discord server](https://discord.gg/Fm8Pwmy),
so you can ping me there, I'm `jak11` (also the Gleam Discord is full of
amazing people so give it a try anyway ✨)
