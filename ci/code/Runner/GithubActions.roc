interface Runner.GithubActions
    exposes [
        run,
    ]
    imports [pf.Task.{ Task }, Job.{ Job }]

run : Job -> Task {} I32
