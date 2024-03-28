# Template

## Design
- When the user runs `compile.roc`, we search for templates ending in `.rtl` (Roc Template Language) in the current directory and load them.
- We then parse each template into a list of nodes, each node being unstructured text, a conditional, an HTML-escaped interpolation, a raw interpolation, or a list. Parsing never fails; if the user makes a syntax error while trying to use one of the template languages features, they will get out plain text instead.
- We then take the parsed templates and generate a file called `Pages.roc` that contains a function corresponding to each template file.
- Each function accepts a single argument called `model`. Normally it is a record, and fields on it are accessed in the template like this `Hello, {{model.name}}!`, although it could be another type.

### Type Inference
- One of my goals with this template language is to get compile time errors. I want to emphasize in the chapter how great it is that Roc has principal decidable type inference, and that it is completely necessary for us to get compile time errors and nice editor support with this kind of approach.
- This approach could be used easily in dynamic languages like JS or Python, but then the compile time errors are lost. If we wanted to use the same approach in a language like Java, with compile time errors, we would have to do real type inference on the template to determine the types in order to include them in the function for the template.

### Parsing
- I wrote my own parser combinators for this to avoid pulling in another dependency. They do not include errors right now because the whole parsing step never fails. Because at least one other chapter will need similar parsing capabilities, I think it would be good to develop a parser in one chapter and use it in the others.
- Right now the generated HTML will contain some whitespace weirdness due to the presence of the extra syntax in the templates. This does not impact the way the HTML is rendered (unless using `pre`), but it would be nice to have it fixed eventually. I haven't thought about it a ton, but it might be a bit challenging to handle properly in all cases, and I think it would probably be a distraction from the point of the chapter.

### When-Is
I would like to include a syntax for when expressions also:
```
{|when x |}
{|is Err NotFound |}
    Error
{|is Ok val |}
    {{ val }}
{|endwhen|}
```
I have not implemented this yet, but I think it should be included if there is enough space. It is probably a fairly uncommmon feature and is necessary for using ADTs nicely in templates.

## Example
To try the example, run `roc ../compile.roc && roc server.roc` in `/example`.
    
## Other options considered
- Originally, I wanted the functions to take a destructured record (`page = \{name, email} ->`) so that fields could be accessed directly in the template without having to prefix them with `model.`. To do this we would have to identify each field being used in the template. This should be doable, but I don't think it is worth increasing the scope of the chapter to do it.
- I have a couple of usages of `crash` in the code right now. These could be removed, but I am a bit torn because I don't like presenting errors that won't actually happen.
- We could have a `.roc` file for each template and then pull them all into a single module which the user imports. This would avoid name conflicts and extra long files, but I don't think it is necessary or worth the increased scope.
