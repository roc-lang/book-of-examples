module [string, number, bool, array, field, map, map2, map3, andThen, or, oneOf, tag, JsonDecoder, DecodingErrors, typeToStr]
import JsonData exposing [Json]

DecodingErrors : [
    FieldNotFound Str,
    WrongJsonType Str,
    KeyNotFound,
    OneOfFailed Str,
    DecoderNotFound Str
]

JsonDecoder t : Json -> Result t DecodingErrors
# check how complicated opaque types

string : JsonDecoder Str
string = \json ->
    when json is
        String str -> Ok str
        _ -> Err (WrongJsonType "$(typeToStr json)")

number : JsonDecoder U64
number = \json ->
    when json is
        Number num -> Ok num
        _ -> Err (WrongJsonType "$(typeToStr json)")

bool : JsonDecoder Bool
bool = \json ->
    when json is
        Boolean b -> Ok b
        _ -> Err (WrongJsonType "$(typeToStr json)")

array : JsonDecoder a -> JsonDecoder (List a)
array = \decoderA ->
    \json ->
        when json is
            Array jsonValues -> List.mapTry jsonValues decoderA
            _ -> Err (WrongJsonType "$(typeToStr json)")

field : Str, JsonDecoder a -> JsonDecoder a
field = \fieldName, decoder ->
    \json ->
        when json is
            Object dict ->
                result = Dict.get dict fieldName 
                Result.try result (\a -> decoder a)

            _ -> Err (WrongJsonType "$(typeToStr json)")

# If the result is Ok, 
# transforms the entire result by running a conversion function on the value the Ok holds. 
# Then returns that new result. If the result is Err, this has no effect. Use onErr to transform an Err.
# try : Result a err, (a -> Result b err) -> Result b err

map : JsonDecoder a, (a -> b) -> JsonDecoder b
map = \decoderA, f ->
    \data -> Result.map (decoderA data) f

map2 : JsonDecoder a, JsonDecoder b, (a, b -> c) -> JsonDecoder c
map2 = \decoderA, decoderB, f ->
    \data ->
        when (decoderA data, decoderB data) is
            (Ok a, Ok b) -> Ok (f a b)
            (Err a, _) -> Err a
            (_, Err b) -> Err b

map3 : JsonDecoder a, JsonDecoder b, JsonDecoder c, (a, b, c -> d) -> JsonDecoder d
map3 = \decoderA, decoderB, decoderC, f ->
    \data ->
        when (decoderA data, decoderB data, decoderC data) is
            (Ok a, Ok b, Ok c) -> Ok (f a b c)
            (Err a, _, _) -> Err a
            (_, Err b, _) -> Err b
            (_, _, Err c) -> Err c

              
# how to write mapN
# is there a way for me to define a function that has n number of input fields does roc let me do this

andThen : (a -> JsonDecoder b), JsonDecoder a -> JsonDecoder b
andThen = \toB, aDecoder ->
    \data ->
        when aDecoder data is
            Ok a -> (toB a) data
            Err a -> Err a

or : JsonDecoder a, JsonDecoder a -> JsonDecoder a
or = \decoderA, decoderB ->
    \data ->
        decoderA data
        |> Result.onErr \_ -> decoderB data

oneOf : List (JsonDecoder a) -> JsonDecoder a
oneOf = \decoders ->
    \json ->
        check = \ds ->
            when ds is
                [head, .. as tail] ->
                    when head json is
                        Ok res -> Ok res
                        Err _ -> check tail

                [] -> Err (OneOfFailed "No decoders provided to oneOf")
        check decoders

tag : Dict Str (JsonDecoder a) -> JsonDecoder a
tag = \decoders ->
    \json ->
        type = (field "#type" string) json
        when type is
            Ok tagName ->
                when Dict.get decoders tagName is 
                    Ok decoder -> decoder json
                    _ -> Err(DecoderNotFound "Could not get decoder for $(tagName) type discriminator")

            _ -> Err (FieldNotFound "Could not find #type discriminator")

typeToStr : Json -> Str
typeToStr = \json ->
    when json is
        String _ -> "String"
        Number _ -> "Number"
        Boolean _ -> "Boolean"
        Object _ -> "Object"
        Array _ -> "Array"

# TODO - Product decoders
# product=\a, b, c, decoderA, decoderB, decoderC, f ->
record : Str, Str, Str, JsonDecoder a, JsonDecoder b, JsonDecoder c, ((a, b, c) -> d) -> JsonDecoder d
altPr : List (Str, JsonDecoder a)

# TESTS
mathsMod =
    Dict.empty {}
    |> Dict.insert "name" (String "Maths 101")
    |> Dict.insert "credits" (Number 200)
    |> Dict.insert "enrolled" (Boolean Bool.true)
    |> Object

phyMod =
    Dict.empty {}
    |> Dict.insert "name" (String "Physics 101")
    |> Dict.insert "credits" (Number 200)
    |> Object

nameDecoder = field "name" string
creditsDecoder = field "credits" number
enrolledDecoder = field "enrolled" bool

# map tests
expect (map nameDecoder \name -> { name: name }) phyMod == Ok ({ name: "Physics 101" })
expect (map enrolledDecoder \name -> { name: name }) phyMod == Err (KeyNotFound)

# map2 tests
expect (map2 nameDecoder creditsDecoder \name, credits -> { name: name, credits: credits }) (phyMod) == Ok ({ name: "Physics 101", credits: 200 })

# map3 tests
expect (map3 nameDecoder creditsDecoder enrolledDecoder \name, credits, enrolled -> { name: name, credits: credits, enrolled: enrolled }) (mathsMod) == Ok ({ name: "Maths 101", credits: 200, enrolled: Bool.true })

# list tests
myList = Array [String "hello", String "world"]
expect (array string) myList == Ok (["hello", "world"])
expect (array string) mathsMod == Err (WrongJsonType "Object")

# field tests
expect nameDecoder mathsMod == Ok ("Maths 101")
expect nameDecoder myList == Err (WrongJsonType "Array")
expect (field "blah" string) mathsMod == Err KeyNotFound

# primitive types
expect string (String "hello") == Ok ("hello")
expect string (Number 123) == Err (WrongJsonType "Number")
expect bool (Boolean Bool.true) == Ok Bool.true
expect number (Number 400) == Ok (400)
# expect null (Null) == Ok ("null")
myotherList = Array [String "s", Nummber 56]
