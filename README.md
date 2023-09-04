![Glam](https://github.com/giacomocavalieri/glam/blob/main/resources/glam_banner.png?raw=true)

[![Package Version](https://img.shields.io/hexpm/v/glam?color=92DCE5)](https://hex.pm/packages/glam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3?color=FCC0D2)](https://hexdocs.pm/glam/)

A package to help you easily pretty print structured data ✨

> ⚙️ This package works with both the Erlang and Javascript target

## Installation

To add this package to your Gleam project:

```sh
gleam add glam
```

## Pretty printing

When working with structured data (like JSON, XML, lists, ASTs, ...) it can
be useful to print it in a nice and tidy way.
Of course, one could go the quick and dirty way and just `string.inspect`
the data structure and call it a day.
However, the result would hardly be readable for complex data structures.

On the other hand, handwriting a pretty printing function can be quite
difficult (I sure have spent my fair share of time writing those) and
error-prone: there are a lot of moving pieces to juggle and it's easy for bugs
to sneak in.

A pretty printing package like Glam provides some basic building blocks to
_describe_ the structure of your data and takes care of the heavy lifting of
actually finding the best layout to format the data, gracefully handling line
limits and indentation.

## Getting started

If you want to get started with Glam, a great starting point is the
[introductory tutorial](https://hexdocs.pm/glam/01_gleam_lists.html) which will
guide you step by step in writing a pretty printer for lists.

By the end of the tutorial you'll know most of the package's API and you'll have
implemented a function that can nicely display lists like this:

```gleam
pretty_list(["Gleam", "is", "fun!"])
|> doc.to_string(10) // Fit the list on lines of width 10

// [
//   "Gleam",
//   "is",   
//   "fun!",   
// ]
```

You can also have a look at the
[`examples`](https://github.com/giacomocavalieri/glam/tree/main/src/examples)
folder in the GitHub repo, there you'll also find a JSON pretty printer.

## Contributing

If you think there's any way to improve this package, or if you spot a bug
don't be afraid to open PRs, issues or requests of any kind!
Any contribution is welcome 💜
