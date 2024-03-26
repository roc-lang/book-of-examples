interface Parser
    exposes [parse]
    imports [Html.{ Node, Attribute }]

# Reference: https://html.spec.whatwg.org/multipage/syntax.html

parse : Str -> Result (List Node) _
parse = \input ->
    {
        input: Str.toUtf8 input,
        line: 1,
        column: 0,
    }
    |> ignoreSpaces
    |> parseNode # TODO: Parse many nodes
    |> Result.map \(node, _) -> [node]

parseNode : State -> Result (Node, State) _
parseNode = \state ->
    when symbol state '<' is
        Ok afterLt ->
            parseNonText afterLt

        Err _ ->
            (text, afterText) = chompWhile state \byte -> byte != '<'

            Ok (Text text, afterText)

parseNonText : State -> Result (Node, State) _
parseNonText = \afterLt ->
    (name, afterName) = chompWhile afterLt isName

    if Str.isEmpty name then
        parseCommentOrDocType afterLt
    else
        # 13.1.2.1 Start tags
        (attributes, afterAttributes) = spaceSeparated afterName parseAttribute

        afterAttributeSpaces = ignoreSpaces afterAttributes

        void = isVoidElement name

        selfClosingResult =
            when symbol afterAttributeSpaces '/' is
                Ok afterSlash if void ->
                    Ok afterSlash

                Ok _ ->
                    Err (SelfClosingNonVoidElement name)

                Err _ ->
                    Ok afterAttributeSpaces

        afterSlash <- Result.try selfClosingResult

        afterGt <-
            ignoreSpaces afterSlash
            |> symbol '>'
            |> Result.try

        # TODO: content
        (content, afterContent) = ([], afterGt)

        when parseEndTag afterContent is
            Ok (endName, afterEnd) if endName == name ->
                if void then
                    Err (VoidElementWithEndTag name)
                else
                    Ok (Element name attributes content, afterEnd)

            Ok (endName, _) ->
                Err (MismatchedTag name endName)

            Err _ if void ->
                Ok (Element name attributes content, afterContent)

            Err _ ->
                Err (ExpectedEndTag name)

isVoidElement : Str -> Bool
isVoidElement = \name ->
    # https://html.spec.whatwg.org/multipage/syntax.html#void-elements
    when name is
        "area"
        | "base"
        | "br"
        | "col"
        | "embed"
        | "hr"
        | "img"
        | "input"
        | "link"
        | "meta"
        | "source"
        | "track"
        | "wbr" ->
            Bool.true

        _ ->
            Bool.false

# 13.1.2.2 End Tags
parseEndTag : State -> Result (Str, State) _
parseEndTag = \state ->
    afterEndSlash <- symbol2 state '<' '/' |> Result.try

    (endName, afterEndName) = chompWhile afterEndSlash isName
    afterEndNameSpaces = ignoreSpaces afterEndName

    afterEndGt <- symbol afterEndNameSpaces '>' |> Result.map
    (endName, afterEndGt)

parseAttribute : State -> Result (Attribute, State) _
parseAttribute = \state ->
    (name, afterName) = chompWhile state isName

    if name == "" then
        Err (ExpectedAttributeName state)
    else
        afterSpaces1 = ignoreSpaces afterName

        when symbol afterSpaces1 '=' is
            Ok afterEqual ->
                afterSpaces2 = ignoreSpaces afterEqual

                when symbol afterSpaces2 '"' is
                    Ok afterQuote1 ->
                        (value, afterValue) = chompWhile afterQuote1 \byte -> byte != '"'

                        symbol afterValue '"'
                        |> Result.map \afterQuote2 ->
                            ((name, value), afterQuote2)

                    Err _ ->
                        (value, afterValue) = chompWhile afterSpaces2 \byte -> byte != ' ' && byte != '>'

                        Ok ((name, value), afterValue)

            Err _ ->
                Ok ((name, ""), afterSpaces1)

parseCommentOrDocType : State -> Result (Node, State) _
parseCommentOrDocType = \afterLt ->
    afterExclamation <- symbol afterLt '!' |> Result.try

    when symbol2 afterExclamation '-' '-' is
        Ok afterStart ->
            parseComment afterStart

        Err _ ->
            parseDocType afterExclamation

parseComment : State -> Result (Node, State) _
parseComment = \afterOpen ->
    next = \state, acc ->
        when nextByte state is
            Next (byte, newState) ->
                if byte == '>' && List.endsWith acc ['-', '-'] then
                    acc
                    |> List.dropLast 2
                    |> Str.fromUtf8
                    |> Result.map \comment -> (Comment comment, newState)
                else
                    next newState (List.append acc byte)

            End ->
                Err (EndedButExpected '-')

    next afterOpen (List.withCapacity 128)

# https://html.spec.whatwg.org/multipage/syntax.html#the-doctype
parseDocType : State -> Result (Node, State) _
parseDocType = \state ->
    word state ['d', 'o', 'c', 't', 'y', 'p', 'e']
    |> Result.try oneOrMoreSpaces
    |> Result.try \afterDoctype -> word afterDoctype ['h', 't', 'm', 'l']
    |> Result.map ignoreSpaces
    |> Result.try \afterHtml -> symbol afterHtml '>'
    |> Result.map \afterGt -> (DoctypeHtml, afterGt)

isBlank : U8 -> Bool
isBlank = \byte -> byte == ' ' || byte == '\t' || isNewLine byte

isNewLine : U8 -> Bool
isNewLine = \byte -> byte == '\n'

isName : U8 -> Bool
isName = \byte -> isAsciiAlpha byte || isAsciiDigit byte || byte == '-' || byte == '_' || byte == '.'

isAsciiAlpha : U8 -> Bool
isAsciiAlpha = \byte -> (byte >= 'a' && byte <= 'z') || (byte >= 'A' && byte <= 'Z')

isAsciiDigit : U8 -> Bool
isAsciiDigit = \byte -> byte >= '0' && byte <= '9'

toLowerAsciiByte : U8 -> U8
toLowerAsciiByte = \byte ->
    if byte >= 'A' && byte <= 'Z' then
        byte + 32
    else
        byte

expect toLowerAsciiByte 'A' == 'a'
expect toLowerAsciiByte 'Z' == 'z'
expect toLowerAsciiByte 'a' == 'a'
expect toLowerAsciiByte 'z' == 'z'

# Parse Tests

# Tags
expect parse "<p></p>" == Ok [Element "p" [] []]
expect parse "<p ></p>" == Ok [Element "p" [] []]
expect parse "<p></p >" == Ok [Element "p" [] []]
expect parse "<h1></h1>" == Ok [Element "h1" [] []]
expect parse "<img src=\"image.png\">" == Ok [Element "img" [("src", "image.png")] []]
expect parse "<img src=\"image.png\" />" == Ok [Element "img" [("src", "image.png")] []]
expect parse "<img src=\"image.png\"></img>" == Err (VoidElementWithEndTag "img")
expect parse "<div />" == Err (SelfClosingNonVoidElement "div")

# Attributes
expect parse "<p id=\"name\"></p>" == Ok [Element "p" [("id", "name")] []]
expect parse "<p id=\"name\" ></p>" == Ok [Element "p" [("id", "name")] []]
expect parse "<p id = \"name\"  class= \"name\"></p>" == Ok [Element "p" [("id", "name"), ("class", "name")] []]
expect parse "<p id=name></p>" == Ok [Element "p" [("id", "name")] []]
expect parse "<button disabled></button>" == Ok [Element "button" [("disabled", "")] []]
expect parse "<p id=\"name\"class=\"name\">" == Err (Expected '>' 'c')

# Mismatched tags
expect parse "<p></ul>" == Err (MismatchedTag "p" "ul")
expect parse "<input" == Err (EndedButExpected '>')
expect parse "<p>" == Err (ExpectedEndTag "p")

# Comments
expect parse "<!---->" == Ok [Comment ""]
expect parse "<!-- comment -->" == Ok [Comment " comment "]
expect parse "<!-- 8 > 5 -->" == Ok [Comment " 8 > 5 "]
expect parse "<!-- - - > -->" == Ok [Comment " - - > "]
expect parse "<!-- -- > -->" == Ok [Comment " -- > "]
expect parse "<!-- before -- after -->" == Ok [Comment " before -- after "]

# Doctype
expect parse "<!doctype html>" == Ok [DoctypeHtml]
expect parse "<!DOCTYPE html>" == Ok [DoctypeHtml]
expect parse "<!DOCTYPE HTML>" == Ok [DoctypeHtml]
expect parse "<!DOCTYPE html >" == Ok [DoctypeHtml]
expect parse "<!DOCTYPE  html>" == Ok [DoctypeHtml]
expect parse "<! DOCTYPE html>" == Err (ExpectedWord ['d', 'o', 'c', 't', 'y', 'p', 'e'] ' ')
expect parse "<!DOCTYPE xml>" == Err (ExpectedWord ['h', 't', 'm', 'l'] 'x')
expect parse "<!doctypehtml>" == Err ExpectedSpace

# Parsing helpers

State : {
    input : List U8,
    line : U32,
    column : U32,
}

nextByte : State -> [Next (U8, State), End]
nextByte = \state ->
    when state.input is
        [] ->
            End

        [byte, .. as rest] ->
            newState =
                if byte == '\n' then
                    {
                        input: rest,
                        line: state.line + 1,
                        column: 1,
                    }
                else
                    {
                        input: rest,
                        line: state.line,
                        column: state.column + 1,
                    }

            Next (byte, newState)

word : State, List U8 -> Result State _
word = \initState, expected ->
    next = \state, remaining ->
        when remaining is
            [] ->
                Ok state

            [head, .. as rest] ->
                when nextByte state is
                    Next (curr, newState) ->
                        if toLowerAsciiByte curr == toLowerAsciiByte head then
                            next newState rest
                        else
                            Err (ExpectedWord expected curr)

                    End ->
                        Err (EndedButExpectedWord expected)

    next initState expected

symbol : State, U8 -> Result State _
symbol = \state, expected ->
    when nextByte state is
        Next (byte, rest) if byte == expected ->
            Ok rest

        Next (byte, _) ->
            Err (Expected expected byte)

        End ->
            Err (EndedButExpected expected)

symbol2 : State, U8, U8 -> Result State _
symbol2 = \state, expected1, expected2 ->
    afterExpected1 <- symbol state expected1 |> Result.try
    symbol afterExpected1 expected2

spaceSeparated : State, (State -> Result (a, State) [ExpectedSpace]err) -> (List a, State)
spaceSeparated = \initState, parser ->
    next = \state, acc ->
        when state |> oneOrMoreSpaces |> Result.try parser is
            Ok (value, newState) ->
                next newState (List.append acc value)

            Err _ ->
                (acc, state)

    # TODO: What is a good initial capacity?
    next initState (List.withCapacity 4)

ignoreSpaces : State -> State
ignoreSpaces = \state ->
    when nextByte state is
        Next (byte, newState) if isBlank byte ->
            ignoreSpaces newState

        Next _ | End ->
            state

oneOrMoreSpaces : State -> Result State [ExpectedSpace]
oneOrMoreSpaces = \state ->
    when nextByte state is
        Next (byte, newState) if isBlank byte ->
            Ok (ignoreSpaces newState)

        Next _ | End ->
            Err ExpectedSpace

chompWhile : State, (U8 -> Bool) -> (Str, State)
chompWhile = \initState, predicate ->
    next = \state, acc ->
        when nextByte state is
            Next (byte, newState) if predicate byte ->
                next newState (List.append acc byte)

            Next _ | End ->
                (
                    Result.withDefault (Str.fromUtf8 acc) "",
                    state,
                )

    next initState []
