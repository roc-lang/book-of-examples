interface Union
    exposes [
        Union2,
        Union3,
        union2Get,
        union3Get,
    ]
    imports [
        Decode,
        Core,
        TotallyNotJson,
    ]

Union3 u1 u2 u3 := [U1 u1, U2 u2, U3 u3]
    implements [
        Eq {
            isEq: union3Eq,
        },
        Decoding {
            decoder: decodeUnionThree,
        },
    ]
union3Eq = \@Union3 a, @Union3 b -> a == b
union3a = \item -> @Union3 (U1 item)
union3b = \item -> @Union3 (U2 item)
union3c = \item -> @Union3 (U3 item)
union3Get = \@Union3 union -> union
# =======DecodeUnion=====
# decodeUnionTwo = Decode.custom \bytes, fmt ->

#     packResult = \{ result, rest }, trans ->
#         when result is
#             Ok r -> Ok { res: trans r, rest: rest }
#             Err a -> Err a
#     unpackResult : _ -> DecodeResult _
#     unpackResult = \packed ->
#         when packed is
#             Ok { res, rest } -> { result: Ok res, rest }
#             Err a -> { result: Err a, rest: bytes }
#     out =
#         bytes
#         |> Decode.decodeWith Decode.decoder fmt
#         |> packResult (\a -> @Union2 (U1 a))
#         |> Result.onErr
#             (\_ -> (bytes |> Decode.decodeWith Decode.decoder fmt) |> packResult \a -> @Union2 (U2 a))
#         |> unpackResult
#     out

##======smart way=====
# singleDecode = \bytes, fmt, union, after ->
#     when bytes |> Decode.decodeWith (Decode.decoder) fmt is
#         { result: Ok res, rest } -> { result: Ok (union res), rest }
#         { result: Err res, rest } -> after { result: Err res, rest }
# makeDec = \bytes, fmt ->
#     firstDec = \union, after -> singleDecode bytes fmt union after
#     nextDec = \union, after -> \_ -> singleDecode bytes fmt union after
#     (firstDec, nextDec)
# decodeUnionThree = Decode.custom \bytes, fmt ->
#     (dec1, dec) = makeDec bytes fmt
#     dec1 union3a (dec union3b (dec union3c \a -> a))

# decodeUnionTwo = Decode.custom \bytes, fmt ->
#     (dec1, dec) = makeDec bytes fmt
#     dec1 union2a (dec union2b \a -> a)

# ====dumb but probably very fast way====

Union2 u1 u2 := [U1 u1, U2 u2]
    implements [
        Eq {
            isEq: union2Eq,
        },
        Decoding {
            decoder: decodeUnionTwo,
        },
    ]
union2Eq = \@Union2 a, @Union2 b -> a == b
union2a = \item -> @Union2 (U1 item)
union2b = \item -> @Union2 (U2 item)
union2Get = \@Union2 union -> union
decodeUnionTwo = Decode.custom \bytes, fmt ->
    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
        { result: Ok res, rest } -> { result: Ok (union2a res), rest }
        _ ->
            when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                { result: Ok res, rest } -> { result: Ok (union2b res), rest }
                { result: Err res, rest } -> { result: Err res, rest }

expect
    name : Result (Union2 U8 { hi : U8 }) _
    name = "{\"hi\":1}" |> Str.toUtf8 |> Decode.fromBytes Core.json
    name == Ok (union2b { hi: 1 })

expect
    name : Result { field : Union2 Str U8 } _
    name =
        """
        {"field":"hi"}
        """
        |> Str.toUtf8
        |> Decode.fromBytes Core.json
    name == Ok ({ field: union2a "hi" })

decodeUnionThree = Decode.custom \bytes, fmt ->
    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
        { result: Ok res, rest } -> { result: Ok (union3a res), rest }
        _ ->
            when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                { result: Ok res, rest } -> { result: Ok (union3b res), rest }
                _ ->
                    when bytes |> Decode.decodeWith (Decode.decoder) fmt is
                        { result: Ok res, rest } -> { result: Ok (union3c res), rest }
                        { result: Err res, rest } -> { result: Err res, rest }
expect
    name : Result (Union3 U8 { hi : U8 } (List U8)) _
    name = "{\"hi\":1}" |> Str.toUtf8 |> Decode.fromBytes Core.json
    name == Ok (union3b { hi: 1 })
expect
    name : Result (Union3 U8 { hi : U8 } (List U8)) _
    name = "[3,4]" |> Str.toUtf8 |> Decode.fromBytes Core.json
    name == Ok (union3c [3, 4])

Option val := [None, Some val]
    implements [
        Eq {
            isEq: optionEq,
        },
        Decoding {
            decoder: optionDecode,
        },
    ]

none = \{} -> @Option None

some = \a -> @Option (Some a)
isNone = \@Option opt ->
    when opt is
        None -> Bool.true
        _ -> Bool.false

optionEq = \@Option a, @Option b ->
    when (a, b) is
        (Some a1, Some b1) -> a1 == b1
        (None, None) -> Bool.true
        _ -> Bool.false

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
    decoded = "{\"y\":1}" |> Str.toUtf8 |> Decode.fromBytes Core.json
    dbg "hil"

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
        |> Decode.fromBytes Core.json
    dbg "hil"

    expected = Ok ({ maybe: some 1u8 })
    isGood =
        when (decoded, expected) is
            (Ok a, Ok b) ->
                a == b

            _ -> Bool.false
    isGood == Bool.true
# finalizer = \fmt, a ->
#     a1=
#         when a.f0 is
#             Ok _ -> a
#             Err NoField ->
#                when Decode.fromBytesPartial [] Decode.decoder fmt is
#                    Ok val -> {state & first: Ok val},
#                    Err _ -> a

#         when f1 is
#             Ok second -> Ok { first, second }
#             Err NoField -> Err TooShort

# finalizer2 = \fmt, a ->
#     when
#         (
#         when
#             when a.f0 is
#                 Err NoField ->
#                     tryDecodes ()
#                 Ok a-> Ok a
#         is
#             Ok f0->
#             Err a

#         f1<-
#             (etc)|>Result.try
#         {f0,f1}

#         )
#         is
#         Ok a->
#         Err a->Error TooShort

