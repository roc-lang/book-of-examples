app "test"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [TotallyNotJson]
    provides [main] to pf
main = 10

finalizer2 = \rec, fmt ->
    when
        when rec.f0 is
            Err _ ->
                when Decode.decodeWith [] Decode.decoder fmt is
                    rec2 -> rec2.result

            Ok a -> Ok a
    is
        Ok f0 ->
            when
                when rec.f1 is
                    Err NoField ->
                        when Decode.decodeWith [] Decode.decoder fmt is
                            rec2 -> rec2.result

                    Ok a -> Ok a
            is
                Ok f1 -> Ok { f1, f0 }
                Err _ -> Err TooShort

        Err _ -> Err TooShort

