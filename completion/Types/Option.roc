interface Types.Option
    exposes [
        some,
        none,
        isNone,
        isSome,
        map,
        or,
        orThen,
    ]
    imports [
        Decode,
        TotallyNotJson,
        Core,
    ]

Option val := [None, Some val]
    implements [
        Eq {
            isEq: optionEq,
        },
        Decoding {
            decoder: optionDecode,
        },
        Encoding {
            toEncoder: optionToEncode,
        },
    ]
map = \@Option opt, fn ->
    when opt is
        Some x -> (x |> fn) |> some
        None -> none {}
or = \@Option opt, default ->
    when opt is
        Some x -> x
        None -> default
orThen = \@Option opt, fn ->
    when opt is
        Some x -> x
        None -> fn {}
none = \{} -> @Option None
some = \a -> @Option (Some a)

isNone = \@Option opt ->
    when opt is
        None -> Bool.true
        _ -> Bool.false

isSome = \@Option opt ->
    when opt is
        None -> Bool.false
        _ -> Bool.true

optionEq = \@Option a, @Option b ->
    when (a, b) is
        (Some a1, Some b1) -> a1 == b1
        (None, None) -> Bool.true
        _ -> Bool.false

optionToEncode : Option val -> Encoder fmt  where val implements Encoding,fmt implements EncoderFormatting
optionToEncode = \@Option val ->
    when val is
        Some contents ->
            Encode.custom \bytes, fmt ->
                bytes |> List.concat (Encode.toBytes contents fmt)
        None -> Encode.custom \bytes, fmt -> []

expect
    encoded =
        dat:{maybe:Option u8,other:Str}
        dat={maybe: none {},other:"hi" }
        Encode.toBytes dat Core.json
        |> Str.fromUtf8

    expected = Ok "{\"other\":\"hi\"}"
    expected == encoded
expect
    encoded =
        dat:Option u8
        dat=@Option None
        Encode.toBytes dat Core.json
        |> Str.fromUtf8

    expected = Ok ""
    expected == encoded
#Encode Option Some
 expect
     encoded =
         { maybe: some 10 }
         |> Encode.toBytes Core.json
         |> Str.fromUtf8

     expected = Ok "{\"maybe\":10}"
     expected == encoded
#Encode Option None


optionDecode = Decode.custom \bytes, fmt ->
    if bytes |> List.len == 0 then
        { result: Ok (@Option (None)), rest: [] }
    else
        when bytes |> Decode.decodeWith (Decode.decoder) fmt is
            { result: Ok res, rest } -> { result: Ok (@Option (Some res)), rest }
            { result: Err a, rest } -> { result: Err a, rest }

# Now I can try to modify the json decoding to try decoding every type with a zero byte buffer and see if that will decode my field
OptionTest : { y : U8, maybe : Option U8 }
expect
    decoded : Result OptionTest _
    decoded = "{\"y\":1}" |> Str.toUtf8 |> Decode.fromBytes TotallyNotJson.json

    expected = Ok ({ y: 1u8, maybe: none {} })
    isGood =
        when (decoded, expected) is
            (Ok a, Ok b) ->
                a == b

            _ -> Bool.false
    isGood == Bool.true

OptionTest2 : { maybe : Option U8 }
expect
    decoded : Result OptionTest2 _
    decoded =
        """
        {"maybe":1}
        """
        |> Str.toUtf8
        |> Decode.fromBytes TotallyNotJson.json

    expected = Ok ({ maybe: some 1u8 })
    expected == decoded

