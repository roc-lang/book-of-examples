app "roc-ci"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br",
        rvn: "../../rvn/package/main.roc",
    }
    imports [
        pf.Task.{ Task },
        pf.Arg.{ Parser },
        pf.Stdout,
        rvn.Rvn,
        Example,
        Runner.GithubActions,
        Runner.Local,
    ]
    provides [main] to pf

main : Task {} I32
main =
    args <- Arg.list |> Task.await

    # Job is currently a module in this project. The plan is for this ci
    # project to turn into a platform, and then the job file will be a Roc
    # application using that platform.
    job = Example.job

    when args is
        [] | ["--local"] -> Runner.Local.run job
        ["--github-actions"] -> Runner.GithubActions.run job
        _ ->
            Stdout.line
                """
                roc-ci

                --local             Run Job on this machine
                --github-actions    Generate github actions files
                --help              This help text
                """
