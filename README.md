# glam

[![Package Version](https://img.shields.io/hexpm/v/glam)](https://hex.pm/packages/glam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glam/)
![CI](https://github.com/giacomocavalieri/glam/workflows/CI/badge.svg?branch=main)

A package to help you easily pretty print structured data ✨

> ⚙️ This package works with both the Erlang and Javascript target

## Installation

To add this package to your Gleam project:

```sh
gleam add glam
```

## Pretty printing

When working with structured data (like JSON, XML, lists, ASTs, ...) it can
be useful to print those.
One could go the quick and dirty way and just `string.inspect` the data
structure and call it a day. However, the result would hardly be readable for
complex data structures.

On the other hand, hand writing a pretty printing function can be quite
difficult (I sure have spent my fair share of time writing those) and error
prone: there's a lot of moving pieces to juggle and its easy for bugs to sneak
in.

A pretty printing package like glam provides some basic building block to
_describe_ the structure of your data and takes care of the heavy lifting of
actually finding the best layout to format the data, gracefully handling line
limits and indentation.

## Getting started

If you want to get started with glam, a great starting point is the
[introductory tutorial](https://hexdocs.pm/glam/01_gleam_lists) which will guide
you step by step in writing a pretty printer for lists.

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

## Contributing

If you think there's any way to improve this package, or if you spot a bug
don't be afraid to open PRs, issues or requests of any kind!
Any contribution is welcome 💜
