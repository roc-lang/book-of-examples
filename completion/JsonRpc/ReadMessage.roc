interface ReadMessage
    exposes [readMessage]
    imports [pf.Task]

readline =\a->Task ""
readMessage = \ ->
    readLine {}
