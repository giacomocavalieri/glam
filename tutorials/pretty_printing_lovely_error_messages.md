# Pretty printing lovely error messages

This tutorial assumes that you already have some familiarity with
pretty printing in Glam and with its API.

If you feel like you need to brush up on your pretty printing skills, you can
first go through the
[introductory tutorial](https://hexdocs.pm/glam/pretty_printing_glamorous_lists.html) and come
back to this one.

## Goals

In this tutorial we'll look into some last bits of Glam's API that were not
covered by the other tutorials. You'll learn how to deal with new lines and
how to flexibly display documents to get the most out of a line.

As a running example we're going to be pretty printing error messages.
It's always a joy to find a compiler with beautifully formatted error messages,
with contextual hints that can point to specific errors in your source code.
If you've ever programmed with Elm or Rust, you'll know what I'm talking about.

In this tutorial we're not concerned with _how_ the errors are generated - we're
not writing a compiler after all - we're just going to pretty print them.
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

- An `Error` has an error code, a name, a long form message, and a `Span` that
  is used to tell which part of the source code it is referencing
- A `Span` is used to point to a specific piece of the source code: it
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

- There should be a header with the error code and its name
- The error's line should be displayed and the columns covered by the span
  should be underlined
- There should be a tooltip starting from the underline that displays the error
  message
- The error message's text should nicely wrap if the space is not enough to fit
  on a single line

To get a sense of how the text wrapping should work, let's have a look at an
error message with a longer description:

```gleam
let source_code = "fn greet(message: String) -> Nil {
  println(\"Hello\" <> message)
}"
let message = "This function is unused!
You can safely remove it or make it public with the `pub` keyword."
let unused_function = Error("E001", "Unused function", message, Span(0, 3, 7))
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
Also, it was considerate enough to leave the new line that was explicitly used.

It may look like a simple example but it's actually remarkable: manually
splitting the error messages would be impossible since they could start at any
point of the source code, being indented by an arbitrary amount of spaces.
On the other hand, hand-writing a function to nicely split the text while also
taking into account the indentation is a pain (trust me,
[I've](https://github.com/giacomocavalieri/prequel/blob/ec293aa066ab2f5e968c994cdb6026058f561470/src/prequel/internals/report.gleam#L381-L444)
[tried](https://github.com/giacomocavalieri/prequel/blob/ec293aa066ab2f5e968c994cdb6026058f561470/src/prequel/internals/extra/string.gleam#L23-L48)).

However, by using a `Document`, the compiler author can forget about these
details and simply focus on writing great error messages!
Everything that has to do with tedious text manipulation will be taken care of
automatically by Glam.

## Flexibly splitting a text

Let's jump straight into the problem of splitting a text in a flexible way:
we want the words to wrap on a new line only if the text wouldn't fit on a
single one.

This kind of _wrapping_ behaviour, however, cannot be achieved by simply using
the functions I showed you in the other tutorials. Let me show you why:

### The problem with `doc.break`s

In all the other tutorials, when we needed to add a space that could be broken
by the pretty printer, we generally used `doc.break` (or `doc.space` and
`doc.soft_break`, which are implemented as a call to `doc.break`).

You may wonder why we cannot use the same approach here as well. I think an
example will be a perfect starting point to get why:

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

As you can see, every single space was broken into a new line. This is the
expected behaviour of a group: it acts a lot like a database transaction
where either no `doc.break` gets broken or _every single one_ inside the group
gets split on a new line.

> I have to thank Louis for the nice analogy with database transactions, it's a
> great way of presenting `doc.group`'s behaviour with regard to breaks.
>
> When I first got into pretty printing and was struggling with the grouping
> behaviour, this way of putting it really made it click for me!

I hope you can now see why this kind of _all or nothing_ behaviour cannot be
used to get the nice word wrapping effect we are looking for.

### Enters `doc.flex_break`

To solve this problem, Glam has another function called `doc.flex_break` which
behaves a lot like a `doc.break`: it is another possible breaking point for the
pretty printer, and it can either be displayed as its first argument (if kept on
a single line) or as its second one (if the pretty printer decides to split the
document).

The fundamental difference lies in the way the pretty printer decides to break
a `doc.flex_break` inside a group: even if the pretty printer decided to
split all normal `doc.break`s inside it, a `doc.flex_break` is never split
unless absolutely necessary. This may sound confusing at first, so let's have a
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

Let's see what happens if we give the document enough space to fit on one line:

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

- The pretty printer runs into the outermost group and it tries to fit
  it on a single line. However, the string `"one two three four"` is longer
  than 10 characters
- The pretty printer commits to breaking every single space inside the group,
  so when it runs into the first two spaces those get split on new lines
- Now the pretty printer has to display the last bit. As I've described before,
  all `doc.flex_break` never get split automatically like normal breaks.
  Now the pretty printer can decide to keep the last `doc.flex_break` on a
  single line if the remaining document fits on a single line
- The string `"three four"` fits perfectly in 10 characters so it is not split.
  If that were a `doc.break` (remember that a `doc.space` is just
  `doc.break(" ", "")`) the pretty printer would have been forced to split it

### Splitting the text

I hope that now you have an intuition on how we could use `doc.flex_break` to
display a text whose words can wrap on new lines as needed:

```gleam
fn flexible_text(text: String) -> Document {
  string.split(line, on: " ")
  |> list.map(doc.from_string)
  |> doc.join(with: doc.flex_space)
  |> doc.group
}
```

We replace every single whitespace in the string with a `doc.flex_space` (which
is just a call to `doc.flex_break(" ", "")`). Now if we try to display an
example text with different line widths we'll get a nice-looking result:

```gleam
let message = "I'm a flexible text and I can wrap on multiple lines!"
flexible_text(message) |> doc.to_string(30)
// ->
// I'm a flexible text and I can
// wrap on multiple lines!

flexible_text(message) |> doc.to_string(15)
// ->
// I'm a flexible
// text and I can
// wrap on
// multiple lines!
```

### Gracefully handling new lines

There's only one small problem with this solution: we're not actually handling
new lines the way one would expect. You can immediately notice this if you add
some nesting to the flexible text:

```gleam
flexible_test("this is a text\nthat is split flexibly")
// ^-- notice how there's a new line here
|> doc.nest(by: 2)
|> doc.to_string(10)
// ->
// this is a
//   text
// that
//   is split
//   flexibly
```

The pretty printer behaved in a kind of surprising way and didn't add
any indentation before the new line... and rightfully so! The pretty printer is
doing the correct thing here.

> When we build a document using `doc.from_string` the pretty printer will
> _never_ split that string, even if it where to exceed the line limit. If it
> tried to be smart and split the raw strings passed to `doc.from_string`, it
> could end up doing more harm than good.
>
> Imagine you're writing a pretty printer for a programming language and the
> pretty printer randomly inserted new lines producing an invalid program. That
> would be quite annoying.
>
> Instead, we want to be really explicit about where the pretty printer is
> allowed to add breaks, hence why the `doc.break` and `doc.flex_break`
> functions.

When we run into a `"\n"` _we - human beings -_ expect to see a new line
and some indentation, but the pretty printer just sees a
`doc.from_string("\n")` and doens't perform any kind of inspection of the
string's content.

Ok this is all nice and cool, but how can we actually add new lines that play
nicely with the pretty printer and can also get indented automatically?

This is the job for `doc.line`: when the pretty printer runs into it, it simply
renders it as a new line. The only difference is that now the pretty printer
_knows_ that is is going on a new line and it can also add indentation!

### Handling new lines in the flexible text

We want to handle new lines gracefully in the flexible text we're building so
that, if we ever need to indent it ~~(foreshadowing)~~, it will still be nicely
rendered by the pretty printer:

```gleam
fn flexible_text(text: String) -> Document {
  let to_flexible_line = fn(line) {
    string.split(line, on: " ")
    |> list.map(doc.from_string)
    |> doc.join(with: doc.flex_space)
    |> doc.group
  }

  string.split(text, on: "\n")
  |> list.map(to_flexible_line)
  |> doc.join(with: doc.line)
  // ^-- replace every `"\n"` with a `doc.line`
  |> doc.group
}
```

> The bottom line is (sorry for the horrible pun, I had to do it): if we ever
> need to join documents together separating those with a new line, we should
> always use `doc.line` so that the pretty printer can handle it correctly and
> also add the needed indentation.

## Displaying the other bits

Splitting the text was the hardest part, now we can focus on other bits of the
error message that shouldn't be too complex.

### The error's header

The error's header is quite straightforward and doesn't require any careful
handling.
We have to concatenate a couple of strings to get the desired look and turn
those into a fixed document with `doc.from_string`:

```gleam
fn header_doc(code: String, name: String) -> Document {
  ["[", code, "]:", name]
  |> string.join(with: " ")
  |> doc.from_string
}
```

### The code line

We want to display the line where the error takes place without changing it.
The pretty printer should never try to split it; imagine if the code in your
error messages looked different from the actual code you've written, that would
be rather confusing!

That also makes things easier for us, we just have to prefix the line with its
number and we can call it a day:

```gleam
fn line_doc(source_code: String, line_number: Int) -> Document {
  let source_code_lines = string.split(source_code, on: "\n")
  let assert Ok(line) = list.at(source_code_lines, line_number)
  doc.from_string(line_prefix(line_number) <> line)
}

fn line_prefix(line_number: Int) -> String {
  int.to_string(line_number + 1) <> " | "
  // ^-- pay attention to the off-by-one errors, lines are 0 based for the error
  //     type but we want them to start from 1 for the user!
}
```

> Notice how we do a `let assert` when extracting the code line from the source
> code lines. This is an assumption that I made to make things a bit simpler: we
> expect that the compiler will always produce a valid error; that is, that any
> error that we're tasked with printing refers to an actual line of the source
> code.

### The underlined pointer

When displaying the pointer, we have to be careful with its size: it's going to
be composed of a single `"┬"` character and a sequence of dashes to underline
the whole span.
We can write a helper function that can create such pointer given the length it
should cover:

```gleam
fn underlined_pointer(length: Int) -> Document {
  [
    doc.from_string("┬" <> string.repeat("─", length - 1)),
    doc.line,
    doc.from_string("╰─ ")
  ]
  |> doc.concat
}
```

> Notice how we use a `doc.line` here as well. Remember: you should use a
> `doc.line` every time you need to join documents separated by a newline!

## Putting everything together

We've written a bunch of small self-contained functions for generating the bits
and pieces needed by the final error message. Now it's time to put everything
together! Our final function's type should turn an `Error` into a `Document`:

```gleam
fn error_to_doc(source_code: String, error: Error) -> Document {
  todo as "let's put everything together!"
}
```

First we'll just `doc.concat` every single document and then start tweaking from there:

```gleam
fn error_to_doc(source_code: String, error: Error) -> Document {
  let underline_size = error.span.column_end - error.span.column_start + 1

  [
    header_doc(error.code, error.name),
    doc.line,
    line_doc(source_code, error.span.line),
    doc.line,
    underlined_pointer(underline_size),
    doc.line,
    flexible_text(error.message),
  ]
  |> doc.concat
}
```

Let's see how this works with an example error:

```gleam
error_to_doc(source_code, unknown_variable)
|> doc.to_string(30)
// ->
// [ E011 ]: Unknown variable
// 2 |   println("Hello" <> message)
// ┬──────
// ╰─ 
// The name `println` is not in
// scope here.
// Did you mean to use
// `io.println`?
```

Not bad! It just needs some finishing touches and it should be good to go:

- The underline should start right under the error location, right now it's
  at the beginning of its line with no indentation
- The text should start at the same line of the pointer and not on a new line
- The text should be indented so that it is always to the right of the pointer

### Joining the text and the pointer

We need to make sure the error message actually starts at the right of the
pointer and not on a new line. In order to do so we can `doc.concat` the two
documents together.

I don't want the body of the `error_to_doc` function to get too big and out of
hand so I'll handle this in an helper function:

```gleam
fn message_doc(message: String, length: Span) -> Document {
  [
    underlined_pointer(span_length),
    flexible_text(message),
  ]
  |> doc.concat
}
```

Let's try this function out and see if it's missing something:

```gleam
message_doc("a long error message that is going to be wrapped", 3)
|> doc.to_string(30)
// ->
// ┬──
// ╰─ a long error message that
// is going to be wrapped
```

Almost there, the text needs to be indented whenever it gets wrapped. The right
amount of indentation is 3 spaces:

```gleam
fn message_doc(message: String, length: Span) -> Document {
  [
    underlined_pointer(span_length),
    flexible_text(message)
    |> doc.nest(by: 3),
  ]
  |> doc.concat
}

message_doc("a long error message that is going to be wrapped", 3)
|> doc.to_string(30)
// ->
// ┬──
// ╰─ a long error message that
//    is going to be wrapped
```

We can now update `error_to_doc` to use this function:

```gleam
fn error_to_doc(source_code: String, error: Error) -> Document {
  let underline_size = error.span.column_end - error.span.column_start + 1

  [
    header_doc(error.code, error.name),
    doc.line,
    line_doc(source_code, error.span.line),
    doc.line,
    message_doc(error.message, underline_size),
  ]
  |> doc.concat
}
```

### Aligning the pointer

Now we just need to move the document produced by `message_doc` to the right to
align it with the starting point of the error message. In order to do that we
can use `doc.nest` like usual.

What's the right amount of indentation needed to align the pointer? If we didn't
add the line number to the left of the code line, we could simply use the span's
`column_start` as the indentation.

Since we added a prefix we also need to take its size into account when aligning
the error message to its starting point:

```text
1 | fn greet(message: String) -> Nil {
^^^^~~~ → this is the span's `column_start`
   ⤷ this is the size of the prefix we added
```

We can achieve this by making a little change to the `line_doc` function to
make it returns the size of the added prefix as well:

```gleam
fn line_doc(source_code: String, line_number: Int) -> #(Document, Int) {
  let source_code_lines = string.split(source_code, on: "\n")
  let assert Ok(line) = list.at(source_code_lines, line_number)
  let prefix = line_prefix(line_number)
  let prefix_size = string.length(prefix)
  #(doc.from_string(prefix <> line), prefix_size)
  // ^-- now we also return the size of the prefix we've added
  //    to the left of the string
}
```

With this we can complete the `error_to_doc` function:

```gleam
fn error_to_doc(source_code: String, error: Error) -> Document {
  let underline_size = error.span.column_end - error.span.column_start + 1
  let #(line_doc, prefix_size) = line_doc(source_code, error.span.line)
  let message_indentation = error.span.column_start + prefix_size

  [
    header_doc(error.code, error.name),
    doc.line,
    line_doc,
    [doc.line, message_doc(error.message, underline_size)]
    // ^-- the line needs to be indented as well, so it's in the same
    //     concat as the message_doc
    |> doc.concat
    |> doc.nest(by: message_indentation),
  ]
  |> doc.concat
}
```

## A bird's eye view

Before closing this tutorial, let's take one last step back to get an overall
view of the code we wrote:

```gleam
fn error_to_doc(source_code: String, error: Error) -> Document
fn header_doc(code: String, name: String) -> Document
fn line_doc(source_code: String, line_number: Int) -> #(Document, Int)
fn message_doc(message: String, length: Int) -> Document
fn underlined_pointer(length: Int) -> Document
```

We ended up writing a bunch of small, self-contained functions and then managed
to join those together with a little effort in the `error_to_doc` function.

What's truly remarkable is how easy it was to build every single piece in
isolation, without having to worry about the context where it was going to be
used.

Take as an example the `underlined_pointer`: we built it ignoring the fact that
it was going to be indented and composed with a flexible text in the end.
At the same time, the `message_doc` didn't have to worry about the fact that we
would later need to align it with the error's starting point.

## Recap

We covered some bits of Glam's API that were not considered in other tutorials:

- `doc.line` as a way to split documents on new lines, playing nicely with the
  pretty printer
- `doc.flex_break` as a way to flexibly split groups without having to commit
  to the all-or-nothing behaviour of normal `doc.break`s

At the same time you also managed to display a beautiful error message; that's
an achievement not to be underestimated!
