# roc-template
An HTML template language for Roc. 

## Example

First write a template like `hello.rtl`:
```
<p>Hello, {{model.name}}!</p>

<ul>
{|list number : model.numbers |}
    <li>{{Num.toStr number}}</li>
{|endlist|}
</ul>

{|if model.isSubscribed |}
<a href="/subscription">Subscription</a>
{|else|}
<a href="/signup">Sign up</a>
{|endif|}
```
Then run `compile.roc` in the directory containing `hello.rtl`. Now call the generated function:
```roc
Pages.hello {
        name: "Isaac",
        numbers: [1, 2, 3],
        isSubscribed: Bool.true,
    }
```
and get your HTML!
```html
<p>Hello, Isaac!</p>

<ul>
    <li>1</li>
    <li>2</li>
    <li>3</li>
</ul>

<a href="/subscription">Subscription</a>
```


## Usage
Running `compile.roc` in a directory containg `.rtl` (Roc Template Language) templates  will generate a file called `Pages.roc` which will expose a normal roc function for each `.rtl` with the same name. Each function accepts a single argument called `model` which can be any type, but will normally be a record.

roc-template supports inserting values, conditionally including content, and expanding over lists. Interpolations, conditionals, and lists all accept arbitrary single-line Roc expressions, so there is no need to learn a new language outside of the template specific features.

The generated file, `Pages.roc` becomes a normal part of your Roc project, so you get type checking right out of the box, for free.

### Inserting Values

To interpolate a value into the document, use double curly brackets:
```
{{ model.firstName }}
```
The value between the brackets must be a `Str`, so conversions may be necessary:
```
{{ 2 |> Num.toStr }}
```
HTML in the interplated string will be escaped to prevent security issues like XSS.

### Lists
Generate a list of values by specifying a pattern for a list element, and the list to be expanded over.
```
{|list paragraph : model.paragraphs |}
<p>{{ paragraph }}</p>
{|endlist|}
```

The pattern can be any normal Roc pattern, so things like this are also valid:
```
{|list (x,y) : [(1,2),(3,4)] |}
<p>X: {{ x |> Num.toStr }}, Y: {{ y |> Num.toStr }}</p>
{|endlist|}
```

### Conditionals
Conditionally include content like this:
```
{|if model.x < model.y |}
Conditional content here
{|endif|}
```
Or with an else block:
```
{|if model.x < model.y |}
Conditional content here
{|else|}
Other content
{|endif|}
```

### Raw Interpolation
If it is necessary to insert content into the document without escaping HTML, use triple brackets.
```
{{{ model.dynamicHtml }}}
```
