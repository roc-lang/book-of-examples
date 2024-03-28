app "compile"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        pf.Path.{ Path },
        pf.File,
        pf.Dir,
        Parser,
        CodeGen,
    ]
    provides [main] to pf

main =
    paths <- Dir.list (Path.fromStr ".")
        |> Task.onErr \e ->
            {} <- Stdout.line "Error listing directories: $(Inspect.toStr e)" |> Task.await
            Task.err 1
        |> Task.map keepTemplates
        |> Task.await

    templates <- taskAll paths \path ->
            File.readUtf8 path
            |> Task.map \template ->
                { path, template }
        |> Task.onErr \e ->
            {} <- Stdout.line "There was an error reading the templates: $(Inspect.toStr e)" |> Task.await
            Task.err 1
        |> Task.await

    {} <- File.writeUtf8 (Path.fromStr "Pages.roc") (compile templates)
        |> Task.onErr \e ->
            {} <- Stdout.line "Error writing file: $(Inspect.toStr e)" |> Task.await
            Task.err 1
        |> Task.await

    Stdout.line "Generated Pages.roc"

taskAll : List a, (a -> Task b err) -> Task (List b) err
taskAll = \items, task ->
    Task.loop { vals: [], rest: items } \{ vals, rest } ->
        when rest is
            [] -> Done vals |> Task.ok
            [item, .. as remaining] ->
                Task.map (task item) \val ->
                    Step { vals: List.append vals val, rest: remaining }

keepTemplates : List Path -> List Path
keepTemplates = \paths ->
    List.keepIf paths \p ->
        Path.display p
        |> Str.endsWith extension

compile : List { path : Path, template : Str } -> Str
compile = \templates ->
    templates
    |> List.map \{ path, template } ->
        { name: extractFunctionName path, nodes: Parser.parse template }
    |> CodeGen.generate

extractFunctionName : Path -> Str
extractFunctionName = \path ->
    display = Path.display path
    when Str.split display "/" is
        [.., filename] if Str.endsWith filename extension ->
            Str.replaceLast filename extension ""

        _ -> crash "Error: $(display) is not a valid template path"

extension = ".rtl"
