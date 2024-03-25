# Software Design by Example in [Roc][roc]

The best way to learn design in any field is to study examples.
These lessons therefore build scale models of tools that programmers use every day
to show how experienced software designers think.
Along the way,
they introduce some fundamental concepts about pure functional languages
that most programmers have never encountered.
*SDXRoc* is a sequel to previous books in [JavaScript][sdxjs] and [Python][sdxpy].

## Topics

| Name               | GitHub ID          | Topic                     | Slug       |
| ------------------ | ------------------ | ------------------------- | ---------- |
| Shritesh Bhattarai | shritesh           | SVG rendering             | svg        |
| Luke Boswell       | lukewilliamboswell | text editor               | editor     |
| Sophie Collard     | sophiecollard      | property-based testing    | proptest   |
| Ashley Davis       | ashleydavis        | thumbnail gallery         | gallery    |
| Eli Dowling        | faldor20           | autocompletion            | completion |
| Kyril Dziamura     | wontem             | file backup               | backup     |
| Norbert Hajagos    | HajagosNorbert     | file transfer             | ftp        |
| Norbert Hajagos    | HajagosNorbert     | discrete event simulation | des        |
| Stuart Hinson      | stuarth            | pattern matching          | match      |
| Fabian Schmalzried | FabHof             | binary data packing       | binary     |
| Isaac Van Doren    | isaacvando         | HTML templates            | template   |
| Jasper Woudenberg  | jwoudenberg        | continuous integration    | ci         |
| Agus Zubiaga       | agu-z              | HTML parser               | parser     |

## Learner Persona

1.  Ning (26) has a college degree in software engineering
    and has been working as a programmer for four years.
    They are comfortable using JavaScript, Python, the Unix shell, Git, and Docker
    to build web applications
    in a team with half a dozen others.

2.  Ning is helping to convert a 20K line legacy front end from JavaScript to TypeScript.
    That experience sparked an interest in strongly-typed languages,
    which led them to experiment with Elm on some personal projects
    and to go through the Roc tutorial.

3.  Ning would like to learn more about functional programming,
    and about the differences between working in interpreted and compiled languages.
    They are also interested in getting involved with an active open source community
    where they might still be able to make a noticeable contribution.

4.  Ning has never done a course on compilers or programming language semantics,
    so they are worried that they don't know enough to start
    and will look foolish if they ask questions.
    In addition,
    their workload means they cannot commit to a regular learning schedule,
    so lessons must be usable in bursts of two or three hours at a time.

## FAQ

-   **Why [Roc][roc] rather than a more established language like Haskell, Clojure, or Elixir?**
    One of the lessons from the previous books is that
    a large language can make design harder to see:
    core ideas might actually have been clearer
    if those books had used a smaller language like Lua.
    This book is also partly an experiment:
    can a project like this early in a language's development
    accelerate its evolution
    by drawing attention to oversights and sources of friction
    while the language is still malleable?

-   **What license are we using?**
    The code is covered by the [MIT License][mit-license],
    so it can be copied, remixed, extended, and incorporated into other projects
    (both open and closed source).
    The prose (i.e., the text of the lessons) is covered by
    the [CC-BY-NC-ND][cc-by-nc-nd] License,
    which means it is free to read
    but people must cite us as the source if they quote or copy it,
    cannot republish it commercially without our permission,
    and cannot create derivative works (e.g., translations) without our permission.
    We may remove some of these restrictions once we have a contract with a publisher,
    but they are in place now because it's much easier to relax a license after the fact
    than to tighten one up.

-   **How do I propose a topic?**
    Create an issue with "topic proposal:" in its title
    and a brief description of what you'd like to cover.
    Greg will triage issues, start discussions, and identify overlaps.

-   **How do I know what topics are taken?**
    Look at the "Topics" section of this file
    or for issues marked [assigned][assigned] in [our repository][repo].

-   **What if I don't have an idea but still want to contribute?**
    Issues labeled [help wanted][help-wanted] in [our repo][repo]
    are topic proposals in search of authors.
    If you are interested in taking one of these on,
    please add a comment to the issue and mention `@gvwilson` to start discussion.

-   **Where should code and notes go?**
    For now,
    each topic should go in a subdirectory of the root directory
    whose name is a short hyphenated slug,
    e.g., `editor` or `http-server`.
    Each topic should be a standalone project;
    please include an `index.md` Markdown file
    with point-form notes about the design of the code.

[assigned]: https://github.com/roc-lang/book-of-examples/labels/assigned
[cc-by-nc-nd]: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode
[help-wanted]: https://github.com/roc-lang/book-of-examples/labels/help-wanted
[mit-license]: https://opensource.org/license/MIT
[repo]: https://github.com/roc-lang/book-of-examples
[roc]: https://www.roc-lang.org/
[sdxjs]: https://third-bit.com/sdxjs/
[sdxpy]: https://third-bit.com/sdxpy/
