interface Runner.Local
    exposes [
        run,
    ]
    imports [pf.Task.{ Task }, Job.{ Job }]

run : Job -> Task {} I32
