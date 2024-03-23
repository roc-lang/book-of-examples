interface Ci
    exposes [
        Job,
        File,
        Dir,

        # Job definition
        Input,
        done,
        step0,
        step1,
        step2,

        # Setup steps
        setupGit,
    ]
    imports [pf.Task.{ Task }, rvn.Rvn, Job]

# TODO: Figure out how to pull File/Dir values out of arbitrary input structures

Job : Job.Job

done = Job.done

Input val := {
    dependsOn : Str,
}

File := {} implements [Encoding, Decoding]

Dir := {} implements [Encoding, Decoding]

step0 : Str,
    Task b Str,
    (Input b -> Job)
    -> Job where b implements Encoding
step0 = \name, run, next ->
    step = {
        name,
        dependencies: [],
        run: \_ ->
            run
            |> Task.map (\output -> Encode.toBytes output Rvn.compact)
            |> Task.mapErr (\err -> UserError err),
    }

    next (@Input { dependsOn: step.name })
    |> Job.addStep step

step1 : Str,
    (a -> Task b Str),
    Input a,
    (Input b -> Job)
    -> Job where a implements Decoding, b implements Encoding
step1 = \name, run, @Input { dependsOn }, next ->
    runSerialized = \inputBytes ->
        when Decode.fromBytes inputBytes Rvn.compact is
            Ok arg ->
                run arg
                |> Task.map (\output -> Encode.toBytes output Rvn.compact)
                |> Task.mapErr (\err -> UserError err)

            Err _ ->
                Task.err InputDecodingFailed

    step = {
        name,
        dependencies: [dependsOn],
        run: runSerialized,
    }

    next (@Input { dependsOn: step.name })
    |> Job.addStep step

step2 : Str,
    (a, b -> Task c Str),
    Input a,
    Input b,
    (Input c -> Job)
    -> Job where a implements Decoding, b implements Decoding, c implements Encoding
step2 = \name, run, @Input input1, @Input input2, next ->
    runSerialized = \inputBytes ->
        { result, rest } = Decode.fromBytesPartial inputBytes Rvn.compact
        arg1 <-
            result
            |> Result.mapErr (\_ -> InputDecodingFailed)
            |> Task.fromResult
            |> Task.await

        result2 = Decode.fromBytes rest Rvn.compact
        arg2 <-
            result2
            |> Result.mapErr (\_ -> InputDecodingFailed)
            |> Task.fromResult
            |> Task.await

        run arg1 arg2
        |> Task.map (\output -> Encode.toBytes output Rvn.compact)
        |> Task.mapErr (\err -> UserError err)

    step = {
        name,
        dependencies: [input1.dependsOn, input2.dependsOn],
        run: runSerialized,
    }

    next (@Input { dependsOn: step.name })
    |> Job.addStep step

setupGit : Task { gitRoot : Dir, branch : Str, hash : Str, author : Str } Str
