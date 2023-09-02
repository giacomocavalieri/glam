# Learning materials

Pretty printing with a package like Glam can be quite confusing at first: it may
take some time to get used to the API, and when writing your first pretty
printers it may be difficult to get the desired look.

Don't be scared, that's normal! The topic is quite challenging, but that's
nothing that some practice cannot fix. There are plenty of learning materials to
get you started, and all the tutorials will walk you through many examples.

If you still find the package has some rough edges that could be improved, if
you feel like you're still not getting how something works, if you're having any
kind of problem with Glam, or even if you just feel like having a chat... please
_do reach out_! I'd love to help and your feedback is always appreciated.
You can find me on [Twitter](https://twitter.com/giacomo_cava), hanging around
the [Gleam Discord server](https://discord.gg/Fm8Pwmy), and I always check the
issues and discussions in the
[Glam repo](https://github.com/giacomocavalieri/glam).

## Step-by-step tutorials

The best way to get started is by reading the Glam tutorials that will guide you
through some example projects to showcase the library API.

You will learn how pretty printing works and write some glamorous pretty
printers for a variety of data structures: simple string lists, todo lists and
JSON.

I suggest you work through the tutorials in this order:

- [Pretty printing glamorous lists](https://hexdocs.pm/glam/pretty_printing_glamorous_lists.html):
  this introductory tutorial will get you up and running with Glam and showcase
  most of the package API. There's also a
  [live stream I did](https://www.youtube.com/watch?v=jxrxr9lH088)
- [Pretty printing TODO lists](https://hexdocs.pm/glam/pretty_printing_todo_lists.html):
  this tutorial goes deeper into how nesting works, and introduces another
  neat function that was omitted in the first tutorial
- [Pretty printing JSON](https://hexdocs.pm/glam/pretty_printing_JSON.html):
  this tutorial walks through the implementation of a JSON pretty printer. It
  won't introduce any new concepts, but it can be a nice exercise to hone your
  pretty printing skills
- [Pretty printing lovely error messages](https://hexdocs.pm/glam/pretty_printing_lovely_error_messages.html):
  this tutorial will walk you through the implementation of a pretty printer for
  the error messages of a made-up programming language. You'll learn about
  another function that was omitted in the introductory tutorial that can help
  you easily build beautiful pretty printers

## Full code examples

If step-by-step tutorials are not your thing, you can still have a look at the
full code examples in the
[project repository](https://github.com/giacomocavalieri/glam/tree/main/src/examples).

## Package API

Of course you can also have a look at the
[package API](https://hexdocs.pm/glam/glam/doc.html): every function is
commented and has a small example to showcase how it can be used.
