interface Parser
    exposes [parse, Node]
    imports []

Node : [
    Text Str,
    Interpolation Str,
    RawInterpolation Str,
    Conditional { condition : Str, trueBranch : List Node, falseBranch : List Node },
    Sequence { item : Str, list : Str, body : List Node },
]

parse : Str -> List Node
parse = \input ->
    when Str.toUtf8 input |> (many node) is
        Match { input: [], val } -> combineTextNodes val
        Match _ -> crash "There is a bug! Not all input was consumed."
        NoMatch -> crash "There is a bug! The parser failed."

combineTextNodes : List Node -> List Node
combineTextNodes = \nodes ->
    List.walk nodes [] \state, elem ->
        when (state, elem) is
            ([.. as rest, Text t1], Text t2) ->
                List.append rest (Text (Str.concat t1 t2))

            (_, Conditional { condition, trueBranch, falseBranch }) ->
                List.append state (Conditional { condition, trueBranch: combineTextNodes trueBranch, falseBranch: combineTextNodes falseBranch })

            (_, Sequence { item, list, body }) ->
                List.append state (Sequence { item, list, body: combineTextNodes body })

            _ -> List.append state elem

Parser a : List U8 -> [Match { input : List U8, val : a }, NoMatch]

# Parsers

node =
    oneOf [
        rawInterpolation,
        interpolation,
        conditionalElse,
        conditionalIf,
        sequence,
        text,
    ]

interpolation : Parser Node
interpolation =
    manyUntil anyByte (string "}}")
    |> startWith (string "{{")
    |> map \bytes ->
        unsafeFromUtf8 bytes
        |> Str.trim
        |> Interpolation

rawInterpolation : Parser Node
rawInterpolation =
    manyUntil anyByte (string "}}}")
    |> startWith (string "{{{")
    |> map \bytes ->
        unsafeFromUtf8 bytes
        |> Str.trim
        |> RawInterpolation

conditionalIf =
    condition <- manyUntil anyByte (string " |}")
        |> startWith (string "{|if ")
        |> leftoverTagSpace
        |> andThen

    endIf =
        string "{|endif|}"
        |> startWith (optional (string "\n"))
        |> leftoverTagSpace

    trueBranch <- manyUntil node endIf
        |> andThen

    val = Conditional {
        condition: unsafeFromUtf8 condition,
        trueBranch,
        falseBranch: [],
    }

    \input -> Match { input, val }

conditionalElse =
    condition <- manyUntil anyByte (string " |}")
        |> startWith (string "{|if ")
        |> leftoverTagSpace
        |> andThen

    elseSep =
        string "{|else|}"
        |> startWith (optional (string "\n"))
        |> leftoverTagSpace

    endIf =
        string "{|endif|}"
        |> startWith (optional (string "\n"))
        |> leftoverTagSpace

    trueBranch <- manyUntil node elseSep
        |> andThen

    falseBranch <- manyUntil node endIf
        |> andThen

    val = Conditional {
        condition: unsafeFromUtf8 condition,
        trueBranch,
        falseBranch,
    }

    \input -> Match { input, val }

sequence : Parser Node
sequence =
    item <- manyUntil anyByte (string " : ")
        |> startWith (string "{|list ")
        |> andThen

    list <-
        manyUntil anyByte (string " |}")
        |> leftoverTagSpace
        |> andThen

    endList =
        string "{|endlist|}"
        |> leftoverTagSpace

    body <- manyUntil node endList
        |> andThen

    val = Sequence {
        item: unsafeFromUtf8 item,
        list: unsafeFromUtf8 list,
        body: body,
    }

    \input -> Match { input, val }

leftoverTagSpace : Parser a -> Parser a
leftoverTagSpace = \parser ->
    parser
    |> endWith (optional (string "\n"))
    |> endWith (many hSpace)

text : Parser Node
text =
    anyByte
    |> map \byte ->
        unsafeFromUtf8 [byte]
        |> Text

hSpace : Parser Str
hSpace =
    oneOf [string " ", string "\t"]

string : Str -> Parser Str
string = \str ->
    \input ->
        bytes = Str.toUtf8 str
        if List.startsWith input bytes then
            Match { input: List.dropFirst input (List.len bytes), val: str }
        else
            NoMatch

anyByte : Parser U8
anyByte = \input ->
    when input is
        [first, .. as rest] -> Match { input: rest, val: first }
        _ -> NoMatch

# Combinators

startWith : Parser a, Parser * -> Parser a
startWith = \parser, start ->
    andThen start \_ ->
        parser

endWith : Parser a, Parser * -> Parser a
endWith = \parser, end ->
    andThen parser \m ->
        end |> map \_ -> m

oneOf : List (Parser a) -> Parser a
oneOf = \options ->
    when options is
        [] -> \_ -> NoMatch
        [first, .. as rest] ->
            \input ->
                when first input is
                    Match m -> Match m
                    NoMatch -> (oneOf rest) input

many : Parser a -> Parser (List a)
many = \parser ->
    help = \input, items ->
        when parser input is
            NoMatch -> Match { input: input, val: items }
            Match m -> help m.input (List.append items m.val)

    \input -> help input []

optional = \parser ->
    \input ->
        when parser input is
            NoMatch -> Match { input, val: {} }
            Match m -> Match { input: m.input, val: {} }

manyUntil : Parser a, Parser * -> Parser (List a)
manyUntil = \parser, end ->
    help = \input, items ->
        when end input is
            Match state -> Match { input: state.input, val: items }
            NoMatch ->
                when parser input is
                    NoMatch -> NoMatch
                    Match m -> help m.input (List.append items m.val)

    \input -> help input []

andThen : Parser a, (a -> Parser b) -> Parser b
andThen = \parser, mapper ->
    \input ->
        when parser input is
            NoMatch -> NoMatch
            Match m -> (mapper m.val) m.input

map : Parser a, (a -> b) -> Parser b
map = \parser, mapper ->
    \in ->
        when parser in is
            Match { input, val } -> Match { input, val: mapper val }
            NoMatch -> NoMatch

unsafeFromUtf8 = \bytes ->
    when Str.fromUtf8 bytes is
        Ok s -> s
        Err _ ->
            crash "I was unable to convert these bytes into a string: $(Inspect.toStr bytes)"

# Tests

expect
    result = parse "foo"
    result == [Text "foo"]

expect
    result = parse "<p>{{name}}</p>"
    result == [Text "<p>", Interpolation "name", Text "</p>"]

expect
    result = parse "{{foo}bar}}"
    result == [Interpolation "foo}bar"]

expect
    result = parse "{{{raw val}}}"
    result == [RawInterpolation "raw val"]

expect
    result = parse "{{{ foo : 10 } |> \\x -> Num.toStr x.foo}}"
    result == [Interpolation "{ foo : 10 } |> \\x -> Num.toStr x.foo"]

expect
    result = parse "{{func arg1 arg2 |> func2 arg2}}"
    result == [Interpolation "func arg1 arg2 |> func2 arg2"]

expect
    result = parse "{|if x > y |}foo{|endif|}"
    result == [Conditional { condition: "x > y", trueBranch: [Text "foo"], falseBranch: [] }]

expect
    result = parse
        """
        {|if x > y |}
        foo
        {|endif|}
        """
    result == [Conditional { condition: "x > y", trueBranch: [Text "foo"], falseBranch: [] }]

expect
    result = parse
        """
        {|if model.field |}
        Hello
        {|else|}
        goodbye
        {|endif|}
        """
    result
    == [
        Conditional {
            condition: "model.field",
            trueBranch: [Text "Hello"],
            falseBranch: [Text "goodbye"],
        },
    ]

expect
    result = parse
        """
        {|if model.someField |}
        {|if Bool.false |}
        bar
        {|endif|}
        {|endif|}
        """
    result
    == [
        Conditional {
            condition: "model.someField",
            trueBranch: [
                Conditional { condition: "Bool.false", trueBranch: [Text "bar"], falseBranch: [] },
            ],
            falseBranch: [],
        },
    ]

expect
    result = parse
        """
        foo
        bar
        {{model.baz}}
        foo
        """
    result == [Text "foo\nbar\n", Interpolation "model.baz", Text "\nfoo"]

expect
    result = parse
        """
        <p>
            {|if foo |}
            bar
            {|endif|}
        </p>
        """
    result
    == [
        Text "<p>\n    ",
        Conditional { condition: "foo", trueBranch: [Text "bar\n    "], falseBranch: [] },
        Text "</p>",
    ]

expect
    result = parse
        """
        <div>{|if model.username == "isaac" |}Hello{|endif|}</div>
        """
    result
    ==
    [
        Text "<div>",
        Conditional { condition: "model.username == \"isaac\"", trueBranch: [Text "Hello"], falseBranch: [] },
        Text "</div>",
    ]

expect
    result = parse
        """
        {|list user : users |}
        <p>Hello {{user}}!</p>
        {|endlist|}
        """

    result
    ==
    [
        Sequence {
            item: "user",
            list: "users",
            body: [
                Text "<p>Hello ",
                Interpolation "user",
                Text "!</p>\n",
            ],
        },
    ]
