interface LspTypes
    exposes []
    imports [
        Types.Union2.{ Union2 },
        Types.Option.{ Option },
        Types.Union5.{ Union5 },
        Core,
    ]
Position : {
    line : U64,
    character : U64,
}
position : _, _ -> Position
position = \line, character -> { line, character }
Range : {
    start : Position,
    end : Position,
}

## Makes a decoder that turns a string into some specific type
stringDecoder = \strToType -> Decode.custom \bytes, fmt ->
        Decode.fromBytesPartial bytes fmt
        |> tryMap strToType

## Makes a decoder that turns a string into an opaque tag type
tagDecoder = \map, opaqueType ->
    stringDecoder \str ->
        map
        |> List.walkUntil (Err TooShort) \state, (tagStr, tag) ->
            if tagStr == str then
                Break (Ok (opaqueType tag))
            else
                Continue state



## MarkupKind: 'plainText'|'markdown'
#TODO:implement encoding
MarkupKind := [PlainText, Markdown] implements [Decoding { decoder: markupKindDecoder }]
markupKindDecoder =
    [
        ("plainText", PlainText),
        ("markdown", Markdown),
    ]
    |> tagDecoder @MarkupKind
# tagDecoder \str->
#     when str is
#         "plainText" -> Ok (@MarkupKind PlainText)
#         "markdown" -> Ok (@MarkupKind Markdown)
#         _ -> Err TooShort

MarkupContent : {
    kind : MarkupKind,
    value : Str,
}
##TODO: This should have some decoding constraints and probably be opaque
DocumentUri : Str

TextDocumentIdentifier : {
    uri : DocumentUri,
}

TextDocumentItem : {
    ## The text document's URI.
    uri : DocumentUri,

    ## The text document's language identifier.
    languageId : Str,

    ## The version number of this document (it will increase after each
    ## change, including undo/redo).
    version : I64,

    ## The content of the opened text document.
    text : Str,
}
WorkDoneProgressParams : {
    workDoneToken : Union2 I64 Str,
}

## Doesn't work
# ProgressToken : Union2 I64 Str

RequestMessageIntern a : {
    id : Union2 I64 Str,
    method : Str,
    # TODO: This should techincally be a union of array and object
    params : Option a,
}
HoverParams : {
    textDocument : TextDocumentIdentifier,
    position : Position,
    workDoneToken : Option (Union2 I64 Str),
}
DidOpenTextDocumentParams : {
    ## The document that was opened.
    textDocument : TextDocumentItem,
}

RequestMessage := [
    Hover (RequestMessageIntern HoverParams),
    DidOpen (RequestMessageIntern DidOpenTextDocumentParams),
]
    implements [
        Decoding {
            decoder: decodeRequestMessage,
        },
    ]
## Try to another decode based on the first decode succeeding
tryResult : DecodeResult _, _ -> _
tryResult = \decoded, try ->
    when decoded.result is
        Err e -> { result: Err e, rest: decoded.rest }
        Ok res -> try res decoded.rest
tryMap : DecodeResult _, _ -> _
tryMap = \decoded, try ->
    when decoded.result is
        Err e -> { result: Err e, rest: decoded.rest }
        Ok res -> { result: try res, rest: decoded.rest }

decodeRequestMessage = Decode.custom \bytes, fmt ->
    decodeRequest = \requestType ->
        Decode.fromBytesPartial bytes fmt
        |> Decode.mapResult \res -> @RequestMessage (requestType res)

    Decode.decodeWith bytes Decode.decoder fmt
    |> tryResult \res, rest ->
        when res.method is
            "textDocument/hover" -> decodeRequest Hover
            "textDocument/didOpen" -> decodeRequest DidOpen
            "textDocument/didOpen" -> decodeRequest DidOpen
            _ -> { result: Err (TooShort), rest }

# =====Testing====
sampleHover =
    """
    {"jsonrpc":"2.0","method":"textDocument/hover","params":{"position":{"character":0,"line":5},"textDocument":{"uri":"file:///home/eli/Code/roc/langServer/main.roc"}},"id":1}        
    """
    |> Str.toUtf8

# Decode HoverParams
expect
    testDecode : Result RequestMessage _
    testDecode = sampleHover |> Decode.fromBytes Core.json
    when testDecode is
        Ok (@RequestMessage (Hover hover)) ->
            hover.params
            |> Types.Option.map (\x -> x.position == (position 5 0))
            |> Types.Option.or Bool.false

        _ -> Bool.false

# RequestMessage should be opaque
# It will have its own decoder.
# In the decoder we will decide which Request it should decode to
# It will return a tag union of all the possible types

ResponseMessageIntern a : {
    id : Option (Union2 I64 Str),
    result : Option (Union5 Str F64 Bool a (List a)),
    # TODO: This should techincally be a union of array and object
    error : Option ResponseErr,
}

ResponseErr : {
    code : I64,
}

ResponseMessage := [
    Hover (ResponseMessageIntern HoverResponse),
]
    implements [
        Decoding {
            decoder: decodeRequestMessage,
        },
        Encoding {
           toEncoder:toEncoder
        }
    ]
toEncoder:ResponseMessage->_
toEncoder= \@ResponseMessage val->
    when val is
        Hover a->
            Encode.custom \bytes,fmt->
                bytes|>Encode.append a fmt

decodeResponseMessage = Decode.custom \bytes, fmt ->
    decodeResponse = \requestType ->
        Decode.fromBytesPartial bytes fmt
        |> Decode.mapResult \res -> @ResponseMessage (requestType res)

    Decode.decodeWith bytes Decode.decoder fmt
    |> tryResult \res, rest ->
        when res.method is
            "textDocument/hover" -> decodeResponse Hover
            _ -> { result: Err (TooShort), rest }

HoverResponse : {
    ##The hover's content
    # Note, usually you can return a markedString or a markedString list,or markupcontent we will only return a markupContent for simplicity
    contents : MarkupContent,

    ## An optional range is a range inside a text document
    ## that is used to visualize a hover, e.g. by changing the background color.
    range : Option Range,
}
