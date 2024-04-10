interface Types.Union5
    exposes [
        Union5,
        get,
        u1,
        u2,
        u3,
        u4,
        u5,
    ]
    imports [
        Decode,
        TotallyNotJson,
    ]

Union5 u1 u2 u3 u4 u5 := [U1 u1, U2 u2, U3 u3, U4 u4, U5 u5]
    implements [
        Eq {
            isEq: isEq,
        },
        Decoding {
            decoder: decoder,
        },
    ]
isEq = \@Union5 a, @Union5 b -> a == b
u1 = \item -> @Union5 (U1 item)
u2 = \item -> @Union5 (U2 item)
u3 = \item -> @Union5 (U3 item)
u4 = \item -> @Union5 (U4 item)
u5 = \item -> @Union5 (U5 item)

get = \@Union5 union -> union

decoder = Decode.custom \bytes, fmt ->
    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
        { result: Ok res, rest } -> { result: Ok (u1 res), rest }
        _ ->
            when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                { result: Ok res, rest } -> { result: Ok (u2 res), rest }
                _ ->
                    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                        { result: Ok res, rest } -> { result: Ok (u3 res), rest }
                        _ ->
                            when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                                { result: Ok res, rest } -> { result: Ok (u4 res), rest }
                                _ ->
                                    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                                        { result: Ok res, rest } -> { result: Ok (u5 res), rest }
                                        { result: Err res, rest } -> { result: Err res, rest }

expect
    name : Result (Union5 U8 { hi : U8 } (List U8) U64 F32) _
    name = "{\"hi\":1}" |> Str.toUtf8 |> Decode.fromBytes TotallyNotJson.json
    name == Ok (u2 { hi: 1 })

expect
    name : Result (Union5 U8 { hi : U8 } (List U8) U64 F32) _
    name = "[3,4]" |> Str.toUtf8 |> Decode.fromBytes TotallyNotJson.json
    name == Ok (u3 [3, 4])

