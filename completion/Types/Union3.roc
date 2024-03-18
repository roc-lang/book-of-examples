interface Types.Union3
    exposes [
        Union3,
        get,
        u1,
        u2,
        u3,
    ]
    imports [
        Decode,
        TotallyNotJson,
    ]

Union3 u1 u2 u3 := [U1 u1, U2 u2, U3 u3]
    implements [
        Eq {
            isEq:isEq,
        },
        Decoding {
            decoder: decoder,
        },
    ]
isEq = \@Union3 a, @Union3 b -> a == b
u1 = \item -> @Union3 (U1 item)
u2 = \item -> @Union3 (U2 item)
u3 = \item -> @Union3 (U3 item)

get = \@Union3 union -> union

decoder = Decode.custom \bytes, fmt ->
    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
        { result: Ok res, rest } -> { result: Ok (u1 res), rest }
        _ ->
            when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                { result: Ok res, rest } -> { result: Ok (u2 res), rest }
                _ ->
                    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                        { result: Ok res, rest } -> { result: Ok (u3 res), rest }
                        { result: Err res, rest } -> { result: Err res, rest }
expect
    name : Result (Union3 U8 { hi : U8 } (List U8)) _
    name = "{\"hi\":1}" |> Str.toUtf8 |> Decode.fromBytes TotallyNotJson.json
    name == Ok (u2 { hi: 1 })

expect
    name : Result (Union3 U8 { hi : U8 } (List U8)) _
    name = "[3,4]" |> Str.toUtf8 |> Decode.fromBytes TotallyNotJson.json
    name == Ok (u3 [3, 4])

