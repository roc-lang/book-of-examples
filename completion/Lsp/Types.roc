interface Types
    exposes []
    imports [Union2,]


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
decodeRequestMessage = Decode.custom \bytes, fmt ->
    decoded : DecodeResult { method : Str }
    decoded = Decode.decodeWith bytes Decode.decoder fmt
    when decoded.result is
        Err e -> { result: Err e, rest: decoded.rest }
        Ok res ->
            decode = \requestType ->
                when Decode.decodeWith bytes Decode.decoder fmt is
                    { result, rest } ->
                        when result is
                            Err e -> { result: Err e, rest }
                            Ok a -> { result: Ok (@RequestMessage (requestType a)), rest }
            when res.method is
                "textDocument/hover" -> decode Hover
                "textDocument/didOpen" -> decode DidOpen
                _ -> { result: Err (TooShort), rest: decoded.rest }

expect
    testDecode:Result RequestMessage _
    testDecode=sample|>Decode.fromBytes Core.json
    when testDecode is
        Ok a-> 
            when  a is
                @RequestMessage (Hover _)-> Bool.true
                _->Bool.false

        Err _->Bool.false

Position : {
    line : U64,
    character : U64,
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

# RequestMessage should be opaque
# It will have its own decoder.
# In the decoder we will decide which Request it should decode to
# It will return a tag union of all the possible types

