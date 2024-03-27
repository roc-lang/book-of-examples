interface Html
    exposes [Node, Attribute]
    imports []

Node : [
    DoctypeHtml,
    Element Str (List Attribute) (List Node),
    Comment Str,
    Text Str,
]

Attribute : (Str, Str)
