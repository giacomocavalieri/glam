# Pretty printing JSON

This tutorial assumes that you already have some familiarity with
pretty printing in Glam and with its API.

If you feel like you need to brush up on your pretty printing skills, you can
first go through the
[introductory tutorial](https://hexdocs.pm/glam/pretty_printing_glamorous_lists.html) and come
back to this one.

## Goals

This tutorial will walk you through the implementation of a pretty printer for
JSON data. It is meant to be a detailed description of the implementation of a
real-life pretty printer, a bit more complicated than those shown in previous
tutorials.

This tutorial assumes you already have some knowledge of the Glam API and won't
dwell on explaining _how_ the pretty printing works, if you feel confused it may
be best to first read the
[introductory tutorial](https://hexdocs.pm/glam/pretty_printing_glamorous_lists.html).

## What's in a JSON?

First things first, let's have a look at the data structure we're going to use
to represent JSON in Gleam:

```gleam
type JSON {
  String(String)
  Number(Float)
  Bool(Bool)
  Null
  Array(List(JSON))
  Object(List(#(String, JSON)))
}
```

A valid JSON object is either a primitive type (a number, a string, a bool or
the literal `null`), or a collection (a sequence of JSON objects, or a
collection of key/value pairs).

## A running example

Me and my friends are hosting a book club and I'm keeping a record for each book
we end up reading and our ratings.
An example record, as written with the JSON type defined above, looks like this:

```gleam
let the_sundial =
  Object([
    #("title", String("The sundial")),
    #("author", String("Shirley Jackson")),
    #("publication_year", Number(1958.0)),
    #("read", Bool(True)),
    #("characters", Array([
      String("Mrs. Halloran"),
      String("Essex"),
    ])),
    #("average_rating", Number(5.0)),
    #("ratings", Array([
      Object([
        #("from", String("Ben")),
        #("value", Number(5.0)),
      ]),
      Object([
        #("from", String("Giacomo")),
        #("value", Number(5.0)),
      ]),
    ])),
  ])
```

I want to write a pretty printer for JSON data to display this in a nice,
human-readable way. The desired output for this object would look like this:

```json
{
  title: "The sundial",
  author: "Shirley Jackson",
  publication_year: 1958.0,
  read: true,
  characters: [ "Mrs. Halloran", "Essex" ],
  average_rating: 5.0,
  ratings: [
    { from: "Ben", value: 5.0 },
    { from: "Giacomo", value: 5.0 }
  ]
}
```

This example already shows all the rules we want our pretty printer to follow,
let's write them down as a reference:

- All strings must be wrapped in double quotes `"`
- Numbers are always printed with their decimal part, even when it's 0
- Booleans are printed as `true` and `false`
- Null is printed as `null`
- It should always try to keep an array on a single line, otherwise (like in
  the case of `reviews`) it should be split with each item on a line of its own
  and indented by two spaces
- It should always try to keep an object on a single line (like the ratings),
  otherwise, it should be split with each field/value pair on a line of its own
- When displaying an object, the field name and the relative value should never
  end up on different lines. If the value is an object/array that needs to be
  split, its open parentheses must be kept on the same line as the field name
  (for example look at the `ratings` field)
- Neither objects nor arrays should have a trailing comma since it's not allowed
  in JSON
- When objects and arrays are displayed on a single line there should be a
  single whitespace separating the parentheses and their items

That's quite a lot of constraints! But, as you'll see, it won't be too
complicated to get a working pretty printer.

## Dealing with primitive data

In order to do anything with the `JSON` type we must first pattern match on it:

```gleam
fn json_to_doc(json: JSON) -> Document {
  case json {
    String(string) -> todo as "string"
    Number(number) -> todo as "number"
    Bool(bool) -> todo as "bool"
    Null -> todo as "null"
    Array(objects) -> todo as "array"
    Object(fields) -> todo as "object"
  }
}
```

Dealing with the primitive data types like string, null, number and bool
shouldn't be too surprising:

```gleam
fn json_to_doc(json: JSON) -> Document {
  case json {
    String(string) -> doc.from_string("\"" <> string <> "\"")
    Number(number) -> doc.from_string(float.to_string(number))
    Bool(bool) -> bool_to_doc(bool)
    Null -> doc.from_string("null")
    Array(objects) -> todo as "array"
    Object(fields) -> todo as "object"
  }
}
```

To turn a boolean value into a document we can define a helper function
`bool_to_doc` (you could also transform the value directly inside the pattern
matching branch, but I'd rather define an helper function to keep things
tidy):

```gleam
fn bool_to_doc(bool: Bool) -> Document {
  bool.to_string(bool)
  |> string.lowercase
  |> doc.from_string
}
```

This is already enough to print simple JSON objects:

```gleam
Bool(True) |> json_to_doc |> doc.to_string(80)
// -> true

Null |> json_to_doc |> doc.to_string(80)
// -> null

String("json!") |> json_to_doc |> doc.to_string(80)
// -> "json!"
```

Not too exciting, but a nice starting point. Let's move on to arrays.

## Pretty printing arrays

Now that we got the simple stuff out of the way we can focus on arrays and
objects. We will start with the former:

```gleam
fn json_to_doc(json: JSON) -> Document {
  case json {
    String(string) -> doc.from_string("\"" <> string <> "\"")
    Number(number) -> doc.from_string(float.to_string(number))
    Bool(bool) -> bool_to_doc(bool)
    Null -> doc.from_string("null")
    Array(objects) -> array_to_doc(objects)
    Object(fields) -> todo as "object"
  }
}

fn array_to_doc(objects: List(JSON)) -> Document {
  todo as "array_to_doc"
}
```

Once again, I'm defining a helper function to keep the pattern matching clean
and readable. As a good starting point, we can turn the array items into a
document and join those with a comma and a breakable space:

```gleam
fn comma() -> Document {
  doc.from_string(",")
}

fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.join(with: doc.concat([comma(), doc.space]))
}
```

> The Glam package also has a `doc.concat_join` function which is a shorthand
> for writing `doc.join(..., with: doc.concat(...))`.
>
> The code I just showed you can be rewritten like this:
>
> ```gleam
> list.map(objects, json_to_doc)
> |> doc.concat_join(with: [comma(), doc.space])
> ```

Now if we try to print an array we get:

```gleam
let array =
  Array([Null, Bool(True), String("json!"), Number(5.0)])
  |> json_to_doc

doc.to_string(array, 80)
// -> null, true, "json!", 5.0

doc.to_string(array, 10)
// ->
// null,
// true,
// "json!",
// 5.0
```

That's looking pretty good, we just have to deal with the square brackets and
nesting. Let's first tackle the brackets problem:

```gleam
fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> doc.prepend_docs([doc.from_string("["), doc.space])
  |> doc.append_docs([doc.space, doc.from_string("]")])
  |> doc.group
}
```

A few things to notice here:

- We use `doc.prepend_docs` and `doc.append_docs` which are just shorthands for
  `doc.prepend(doc.concat(...))` and `doc.append(doc.concat(...))`
- We add a breakable `doc.space` after the open bracket and before the closing
  one. When the pretty printer outputs the array on a single line there will
  be a space to separate the item from the brackets; however, if the array does
  not fit on a single line, that space will be broken making sure that open and
  closed brackets will be kept on a separate line
- We wrap everything in a `doc.group`: this tells the pretty printer that it is
  allowed to break the spaces inside it if it doesn't fit on a single line

Last, we can add indentation for when the array gets broken on multiple lines:

```gleam
fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> doc.prepend_docs([doc.from_string("["), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string("]")])
  |> doc.group
}
```

`doc.nest` must go _before_ the closing bracket; otherwise, even its preceding
space would get indented, resulting in the closing bracket being more indented
than the opening one.

If don't want to take my word for it and want to see it with your own eyes, try
to move `doc.group` below the closed parentheses;
an array split on multiple lines would look like this:

```json
[
  true,
  false
  ] // <- this is indented!
```

## Pretty printing objects

We need one last piece to complete the JSON pretty printer: a way to nicely
output objects. You'll find out that it's remarkably similar to pretty printing
arrays.

```gleam
fn json_to_doc(json: JSON) -> Document {
  case json {
    String(string) -> doc.from_string("\"" <> string <> "\"")
    Number(number) -> doc.from_string(float.to_string(number))
    Bool(bool) -> bool_to_doc(bool)
    Null -> doc.from_string("null")
    Array(objects) -> array_to_doc(objects)
    Object(fields) -> object_to_doc(fields)
  }
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  todo as "object_to_doc"
}
```

How to turn a field/value pair into a document? We can first display the name, a
colon, and the value document that we can get with a recursive call to
`json_to_doc`:

```gleam
fn colon() -> Document {
  doc.from_string(":")
}

fn field_to_doc(field: #(String, JSON)) -> Document {
  let #(name, value) = field
  let name_doc = doc.from_string(name)
  let value_doc = json_to_doc(value)
  [name_doc, colon(), doc.from_string(" "), value_doc]
  |> doc.concat
}
```

The only point that needs extra attention here is the use of `doc.from_string(" ")`
as a whitespace instead of `doc.space`. If you remember from the introductory
tutorial (or the package documentation), a `doc.space` can always be broken by
the pretty printer into a new line; however, we said we want the field name to
always stay on the same line as its value.

To get this result we must use a single whitespace that doesn't also act as a
possible breaking point.
Since the pretty printer will never split documents obtained from a
`doc.from_string`, we can use it with a single whitespace string like in the
code snippet above.

### Putting everything together

Now that we can turn a single field/value pair into a document we can get back
to the problem of turning an entire object into a document:

- Transform every field/value pair into a document
- Join those together with a comma and a breakable space
- Enclose everything in open and closed curly brackets
- Nest the object fields

```gleam
fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  list.map(fields, field_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> doc.prepend_docs([doc.from_string("{"), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string("}")])
  |> doc.group
}
```

That's it, we can now print JSON objects:

```gleam
let object =
  Object([#("field1", Null),  #("field2", Bool(True))])
  |> json_to_doc

doc.to_string(object, 80)
// -> { field1: null, field2: true }

doc.to_string(object, 20)
// ->
// {
//   field1: null,
//   field2: true   
// }
```

## Some finishing touches

The tutorial could end here and we'd have written a rad JSON pretty printer.
But there's a small piece of redundant code that is an eyesore to me, let's have
a look at the code for turning objects and arrays into nice-looking documents:

```gleam
fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> doc.prepend_docs([doc.from_string("["), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string("]")])
  |> doc.group
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  list.map(fields, field_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> doc.prepend_docs([doc.from_string("{"), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string("}")])
  |> doc.group
}
```

That's almost exactly the same code! We've duplicated the logic with which we
parenthesise objects and arrays, let's pull it out in its own function:

```gleam
fn parenthesise(document: Document, open: String, close: String) -> Document {
  document
  |> doc.prepend_docs([doc.from_string(open), doc.space])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.space, doc.from_string(close)])
  |> doc.group
}
```

And the original code can be rewritten using it:

```gleam
fn array_to_doc(objects: List(JSON)) -> Document {
  list.map(objects, json_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> parenthesise("[", "]")
}

fn object_to_doc(fields: List(#(String, JSON))) -> Document {
  list.map(fields, field_to_doc)
  |> doc.concat_join(with: [comma(), doc.space])
  |> parenthesise("{", "}")
}
```

Now I can proudly say we're done. If you try printing the big object I showed
you at the beginning of the tutorial, you'll see an output like this:

```gleam
json_to_doc(the_sundial) |> doc.to_string(20)
// ->
// {
//   title: "The sundial",
//   author: "Shirley Jackson",
//   publication_year: 1958.0,
//   read: true,
//   characters: [
//     "Mrs. Halloran",
//     "Essex"
//   ],
//   average_rating: 5.0,
//   ratings: [
//     {
//       from: "Ben",
//       value: 5.0
//     },
//     {
//       from: "Giacomo",
//       value: 5.0
//     }
//   ]
// }
```

Try to play around with the line width to see how the output adapts to it!
