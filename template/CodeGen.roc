interface CodeGen
    exposes [generate]
    imports [Parser.{ Node }]

generate : List { name : Str, nodes : List Node } -> Str
generate = \templates ->
    functions =
        List.map templates renderTemplate
        |> Str.joinWith "\n\n"
    names =
        List.map templates .name
        |> Str.joinWith ",\n"
        |> indent
        |> indent

    """
    interface Pages
        exposes [
    $(names)
        ]
        imports []

    $(functions)

    escapeHtml : Str -> Str
    escapeHtml = \\input ->
        input
        |> Str.replaceEach "&" "&amp;"
        |> Str.replaceEach "<" "&lt;"
        |> Str.replaceEach ">" "&gt;"
        |> Str.replaceEach "\\"" "&quot;"
        |> Str.replaceEach "'" "&#39;"

    """

# \""

RenderNode : [
    Text Str,
    Conditional { condition : Str, trueBranch : List RenderNode, falseBranch : List RenderNode },
    Sequence { item : Str, list : Str, body : List RenderNode },
]

renderTemplate : { name : Str, nodes : List Node } -> Str
renderTemplate = \{ name, nodes } ->
    body =
        condense nodes
        |> renderNodes

    """
    $(name) = \\model ->
    $(body)
    """

renderNodes : List RenderNode -> Str
renderNodes = \nodes ->
    when List.map nodes toStr is
        [] -> "\"\"" |> indent
        [elem] -> elem
        blocks ->
            list = blocks |> Str.joinWith ",\n"
            """
            [
            $(list)
            ]
            |> Str.joinWith ""
            """
            |> indent

toStr = \node ->
    block =
        when node is
            Text t ->
                """
                \"""
                $(t)
                \"""
                """

            Conditional { condition, trueBranch, falseBranch } ->
                """
                if $(condition) then
                $(renderNodes trueBranch)
                else
                $(renderNodes falseBranch)
                """

            Sequence { item, list, body } ->
                """
                List.map $(list) \\$(item) ->
                $(renderNodes body)
                |> Str.joinWith ""
                """
    indent block

condense : List Node -> List RenderNode
condense = \nodes ->
    List.map nodes \node ->
        when node is
            RawInterpolation i -> Text "\$($(i))"
            Interpolation i -> Text "\$($(i) |> escapeHtml)"
            Text t ->
                # Escape Roc string interpolations from the template
                escaped = Str.replaceEach t "$" "\\$"
                Text escaped

            Sequence { item, list, body } -> Sequence { item, list, body: condense body }
            Conditional { condition, trueBranch, falseBranch } ->
                Conditional {
                    condition,
                    trueBranch: condense trueBranch,
                    falseBranch: condense falseBranch,
                }
    |> List.walk [] \state, elem ->
        when (state, elem) is
            ([.. as rest, Text x], Text y) ->
                combined = Str.concat x y |> Text
                rest |> List.append combined

            _ -> List.append state elem

indent : Str -> Str
indent = \input ->
    Str.split input "\n"
    |> List.map \str ->
        Str.concat "    " str
    |> Str.joinWith "\n"
