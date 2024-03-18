app "test"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [TotallyNotJson, pf.Stdout, Decode]
    provides [main] to pf

UserName := Str implements [
        Eq { isEq: userNameEq },
        Decoding {
            decoder: userNameDecode,
        },
    ]
userNameEq = \@UserName a, @UserName b -> a == b
userNameDecode = Decode.custom \bytes, fmt ->
    bytes
    |> Decode.fromBytesPartial fmt
    |> Decode.mapResult @UserName

Alias : { user: UserName }
expect
    prog =
        """
        {"user":"name"}
        """
        |> Str.toUtf8
    rec : Result Alias _
    rec = prog |> Decode.fromBytes TotallyNotJson.json
    rec == Ok { user: @UserName "name" }

AliasBad : UserName 
expect
    prog =
        "name"
        |> Str.toUtf8
    rec : Result AliasBad _
    rec = prog |> Decode.fromBytes TotallyNotJson.json
    rec == @UserName "name" |>Ok

main = Stdout.line "hi"
