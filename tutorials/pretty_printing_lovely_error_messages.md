# Pretty printing lovely error messages

This tutorial assumes that you already have some familiarity with
pretty printing in Glam and with its API.

If you feel like you need to brush up on your pretty printing skills, you can
first go through the
[introductory tutorial](https://hexdocs.pm/glam/01_gleam_lists.html) and come
back to this one.

## Goals

In this tutorial we'll look into some last bits of Glam's API that were not
covered by the other tutorials. You'll learn how to deal with new lines and
how to flexibly display documents to get the most out of a line width.

As a running example we're going to be pretty printing error messages.
It's always a joy to find a compiler with beautifully formatted error messages,
with contextual hints and that can point to specific errors in your source code.
If you've ever programmed with Elm or Rust, you'll know what I'm talking about.

In this tutorial we're not concerned with _how_ the errors are generated - we're
not writing a compiler after all - but we're going to just pretty print those.
The reference data structure I'm going to use is this one:

```gleam
type Span {
  Span(line: Int, column_start: Int, column_end: Int)
}

type Error {
  Error(code: String, name: String, message: String, span: Span)
}
```

It's quite bare-bones but more than enough for our needs:

- an `Error` has an error code, a name, a long form message, and a `Span` that
  is used to tell which part of the source code this is referencing
- a `Span` is used to point to a specific point of the source code: it
  references a line and can span multiple columns

Let's look at an example error to make things clearer:

```gleam
let source_code = "fn greet(message: String) -> Nil {
  println(\"Hello\" <> message)
}"
let message = "The name `println` is not in scope here.
Did you mean to use `io.println`?"
let unknown_variable = Error("E011", "Unknown variable", message, Span(1, 2, 8))
```

How should this error look? This is what we're going for look-wise:

```text
[ E011 ]: Unknown variable
2 |   println("Hello" <> message)
      ┬─────
      ╰─ The name `println` is not in scope here.
         Did you mean to use `io.println`?
```

Pretty nice, isn't it? There are a couple rules that the pretty printed error
message should follow:

- there should be a header with the error code and its name
- the error's line should be displayed and the columns covered by the span
  should be underlined
- there should be a tooltip starting from the underline that displays the error
  message
- the error message's text should nicely wrap if the space is not enough to fit
  on a single line

To get a sense of how the text wrapping should work, let's have a look at an
error message with a longer description:

```gleam
let source_code = "fn greet(message: String) -> Nil {
  println(\"Hello\" <> message)
}"
let message = "This function is unused!
You can safely remove it or make it public with the `pub` keyword."
let error = Error("E001", "Unused function", message, Span(0, 3, 7))
```

```text
[ E001 ]: Unused function
1 | fn greet(message: String) -> Nil {
       ┬───
       ╰─ This function is unused!
          You can safely remove it or make it public with
          the `pub` keyword.
```

As you can see here, the pretty printer splits the error message's second line
in order to fit the text in the allowed width (60 characters in this case).
Also, it was considerate enough to leave the newline that was explicitly used.

It may look like a simple example but it's actually remarkable: manually
splitting the error messages would be impossible since they could start at any
point of the source code, being indented by an arbitrary amount of spaces.
On the other hand, hand-writing a function to nicely split the text while also
taking into account the indentation is a pain (trust me,
[I've](https://github.com/giacomocavalieri/prequel/blob/ec293aa066ab2f5e968c994cdb6026058f561470/src/prequel/internals/report.gleam#L381-L444) [tried](https://github.com/giacomocavalieri/prequel/blob/ec293aa066ab2f5e968c994cdb6026058f561470/src/prequel/internals/extra/string.gleam#L23-L48))

However, by using a `Document`, the compiler author can forget about these
details and simply focus on writing great error messages!
Everything that has to do with tedious text manipulation will be taken care of
automatically by Glam.

## Flexibly splitting a text

Let's jump right away into the problem of splitting a text in a flexible way:
we want the words to wrap on a newline only if the text wouldn't fit on a single
one.

This kind of _wrapping_ behaviour, however, cannot be achieved simply using the
functions I showed you in the other tutorials. Let me show you why:

### The problem with `doc.break`s

In all the other tutorials, when we needed to add a space that could be broken
by the pretty printer we generally used `doc.break` (or `doc.space` and
`doc.soft_break`, which are implemented as a call to `doc.break`).

You may wonder why we cannot use the same approach here as well. I think an
example will be a perfect starting point:

```gleam
let text =
  ["Lorem", "ipsum", "dolor", "sit", "amet"]
  |> list.map(doc.from_string)
  |> doc.join(with: doc.space)
  |> doc.group

text |> doc.to_string(20)
// ->
// Lorem
// ipsum
// dolor
// sit
// amet
```

As you can see, every single space was broken into a newline. This is normal and
the expected behaviour of a group: it acts a lot like a database transaction
where either no space get broken or _every single space_ inside the group
gets split on a newline.

> I have to thank Louis for the great analogy with database transactions, it's a
> great way of presenting `doc.group`'s behaviour with regard to breaks.
>
> When I first got into pretty printing and was struggling with the grouping
> behaviour, this way of putting it really made it click for me!

I hope you can now see why this kind of _all or nothing_ behaviour cannot be
used to get the nice word wrapping effect we are looking for.

### Enters `doc.flex_break`

To solve this problem, Glam has another function called `doc.flex_break` which
behaves a lot like a `break`: it is another possible breaking point for the
pretty printer, and it can either be displayed as its first argument (if kept on
a single line) or as its second one (if the pretty printer decides to split the
document).

The fundamental difference lies in the way the pretty printer decides to break
a `doc.flex_break` inside a group: even if the pretty printer decided to
split all normal `doc.break`s inside it, a `doc.flex_break` is never split
unless absolutely necessary. I know this may sound confusing, so let's have a
look at an example:

```gleam
let text =
  [
    doc.from_string("one"),
    doc.space,
    doc.from_string("two"),
    doc.space,
    doc.from_string("three"),
    doc.flex_break(" ", ""),
    doc.from_string("four"),
  ]
  |> doc.join
  |> doc.group
```

Let's first see what happens if we give the document enough space to fit on one
line:

```gleam
doc.to_string(text, 80)
// -> one two three four
```

So far so good, we could have expected this result. Now let's see what happens
if we reduce the line width:

```gleam
doc.to_string(text, 10)
// ->
// one
// two
// three four
```

This may be surprising so let's work it out step-by-step:

- the pretty printer runs into the group with all documents, it tries to fit it
  on a single line, but the string `"one two three four"` is longer than 10
  characters
- the pretty printer commits to breaking every single space inside the group, so
  when it runs into the first two spaces those get split one new lines
- now the pretty printer has to display the last bit. As I've described you
  before, all `doc.flex_break` never get split automatically like normal breaks.
  Now the pretty printer can decide to keep the last `doc.flex_break` on a
  single line if the remaining document fits on a single line
- the string `"three four"` fits perfectly in 10 characters so it is not split.
  If that were a `doc.break` (remember that a `doc.space` is just
  `doc.break(" ", "")`) the pretty printer would have been forced to split it
