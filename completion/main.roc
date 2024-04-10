app "lang-server"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [pf.Stdout, pf.Stdin, pf.Task, Decode.{ DecodeResult },  Union.{ Union2, Option },Core]
    provides [main] to pf
##Converts a result to a task then awaits it
awaitResult = \res, next -> res |> Task.fromResult |> Task.await next

sample =
    """
    {"jsonrpc":"2.0","method":"textDocument/hover","params":{"position":{"character":0,"line":5},"textDocument":{"uri":"file:///home/eli/Code/roc/langServer/main.roc"}},"id":1}        
    """
    |> Str.toUtf8
# decoder = Core.jsonWithOptions { fieldNameMapping: PascalCase }

# StringOrInt : [String Str, Number U64]
# Message : { jsonrpc : Str, id : StringOrInt }
##Doesn't work 
#Id : Union2 Str I64

main =
    Stdout.line "done"

# RequestMessage={
# jsonrpc:Str,
# id: U64| Str,
# method: Str,

# params? array | object}

# messageEnd = "\n\r"
# messageHandler=
# parse

##====JSONRPC Implimentation====##

sendMessage = \messageBytes ->
    len = messageBytes |> List.len
    messageStr <- messageBytes |> Str.fromUtf8 |> awaitResult
    msg = "Content-Type: $(len |> Num.toStr)\r\n\r\n$(messageStr)"
    Stdout.write msg

messageLoop : (List U8 -> Task.Task [Continue, Exit] _) -> _
messageLoop = \messageHandler ->
    Task.loop [] \leftOver ->
        { content, leftOver: nextLeftOver } <- readMessage leftOver |> Task.await
        continue <- messageHandler content |> Task.map
        when continue is
            Exit -> Done []
            Continue -> Step nextLeftOver

readMessage = \partialMessage ->
    # This is slow, we don't need to check the whole thing, just the new message with 3 chars from the previous message appended at the start, so the last 256+3 (259)
    message <- readTill partialMessage (\msg -> (msg |> List.walkUntil [] matchContentStart) == ['\r', '\n', '\r', '\n']) |> Task.await
    message |> parseMessage

matchContentStart = \state, char ->
    when (state, char) is
        (['\r', '\n', '\r'], '\n') -> Break (state |> List.append char)
        (['\r', '\n'], '\r')
        | (['\r'], '\n')
        | ([], '\r') -> Continue (state |> List.append char)

        _ -> Continue []

readTill = \message, pred ->
    Task.loop message \msg ->
        bytes <- Stdin.bytes |> Task.map
        newMsg = msg |> List.concat bytes
        if pred newMsg then
            Done newMsg
        else
            Step newMsg

readTillAtLeastLen = \msg, len -> readTill msg \newMsg -> List.len newMsg >= len
# TODO!: header is ascii encoded

parseMessage : List U8 -> _
parseMessage = \message ->
    { before: header, after } <- message |> Str.fromUtf8 |> Result.try (\s -> Str.splitFirst s "\r\n\r\n") |> awaitResult
    length <- getContentLength header |> awaitResult
    read <- (after |> Str.toUtf8 |> readTillAtLeastLen length) |> Task.map
    { before: content, others: leftOver } = read |> List.split length
    { content, leftOver }

## Get's the content lenght header
## Tolerant of having an unparsed body from a malformed message in the header section because it looks from the end of the text we think is a header
getContentLength = \header ->
    headers = header |> Str.split "\r\n"
    contentHeaderName = "Content-length: "
    # we do contians here because if we failed to parse the last body it might be stuck at the end of this header
    contentHeader = headers |> List.findFirst \a -> a |> Str.contains contentHeaderName
    when contentHeader is
        Err _ -> Err NoContentHeader
        Ok cHead ->
            # Because we might have some junk before this header we just keep anything after the header name
            cHead |> Str.splitLast "Content-length: " |> Result.try \split -> split.after |> Str.toU64

test = \content ->
    length = content |> Str.countUtf8Bytes
    """
    Content-Length: $(length |> Num.toStr)\r\n\r\n$(content)
    """

