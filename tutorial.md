-- Super rough outline for a JSON pretty printer follow along tutorial

Let's write a JSON pretty printer.

JSON type definition:

```gleam
type Json {
  Array(List(Json))
  Number(Float)
  Object(List(#(String, Json)))
  String(String)
  Bool(Bool)
  Null
}
```

To pretty print a JSON we have to turn it into a `Document`.
We will start with the simple bits and build up a full-fledged JSON pretty printer.

A good starting point is to pattern match on a JSON:

```gleam
pub fn to_document(json: JSON) -> Document {
  case json {
    Null -> todo("null")
    Bool(boolean) -> todo("boolean")
    String(string) -> todo("string")
    Number(number) -> todo("number")
    Object(fields) -> todo("object")
    Array(items) -> todo("array")
  }
}
```

We can start addressing the base cases which shouldn't be too hard.
What we need is a way to build a `Document` from a given string, this way we can
display a null or boolean value. We can do this in Glam using the `text` function
from the `doc` module:

```gleam
fn boolean_to_document(boolean: Bool) -> Document {
  case boolean {
    True -> doc.text("true")
    False -> doc.text("false")
  }
}
```

Now, with the `boolean_to_document` function we can pretty print JSON boolean values!

```gleam
pub fn to_document(json: JSON) -> Document {
  case json {
    Null -> todo("null")
    Bool(boolean) -> boolean_to_document(boolean)
    String(string) -> todo("string")
    Number(number) -> todo("number")
    Object(fields) -> todo("object")
    Array(items) -> todo("array")
  }
}
```

```gleam
pub fn main() {
  Bool(False)
  |> to_document
  |> format(80)
}

// -> false
```

Talk about `format`.

Thanks to `doc.text` we can also implement the transformation to document for the
other base cases:

```gleam
pub fn to_document(json: JSON) -> Document {
  case json {
    Null -> doc.text("null")
    Bool(boolean) -> boolean_to_document(boolean)
    String(string) -> doc.text(string)
    Number(number) -> doc.text(float.to_string(number))
    Object(fields) -> todo("object")
    Array(items) -> todo("array")
  }
}
```


