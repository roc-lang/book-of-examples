interface Job
    exposes [
        Job,
        addStep,
        done,
        spec,
        JobSpec,
        Step,
        RunError,
    ]
    imports [pf.Task.{ Task }]

Job := JobSpec

JobSpec : List [Step Step, ConstructionError Str]

RunError : [UserError Str, InputDecodingFailed]

Step : {
    name : Str,
    dependencies : List Str,
    run : List U8 -> Task (List U8) RunError,
}

addStep : Job, Step -> Job
addStep = \@Job steps, step ->
    nameAlreadyUsed = List.any
        steps
        (\otherStep ->
            when otherStep is
                ConstructionError _ -> Bool.false
                Step { name } -> name == step.name
        )
    if nameAlreadyUsed then
        @Job (List.append steps (ConstructionError "Duplicate step name: $(step.name)"))
    else
        @Job (List.append steps (Step step))

done : Job
done = @Job []

spec : Job -> JobSpec
spec = \@Job job -> job
