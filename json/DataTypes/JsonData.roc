module [Json]

Json : [
    String Str,
    Number U64,
    Boolean Bool,
    Object (Dict Str Json),
    Array (List Json),
]

