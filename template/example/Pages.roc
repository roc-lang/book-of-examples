interface Pages
    exposes [
        blogPost,
        home
    ]
    imports []

blogPost = \model ->
    """
    <!DOCTYPE html>
    <html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>$(model.post.title |> escapeHtml) - Roc Template Example</title>
    </head>
    <body>
        <div>
            <h1>$(model.post.title |> escapeHtml)</h1>
            <p>$(model.post.text |> escapeHtml)</p>
            <a href="/">Home</a>
        </div>
    </body>
    </html>
    
    """

home = \model ->
    [
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <title>Roc Template Example Blog</title>
        </head>
        <body>
            <div>
                <h1>Posts</h1>
                <ul>
                
        """,
        List.map model.posts \post ->
            """
            <li>
                            <a href="/posts/$(post.slug |> escapeHtml)">$(post.title |> escapeHtml)</a>
                        </li>
                    
            """
        |> Str.joinWith "",
        """
        </ul>
            </div>
        </body>
        </html>
        
        """
    ]
    |> Str.joinWith ""

escapeHtml : Str -> Str
escapeHtml = \input ->
    input
    |> Str.replaceEach "&" "&amp;"
    |> Str.replaceEach "<" "&lt;"
    |> Str.replaceEach ">" "&gt;"
    |> Str.replaceEach "\"" "&quot;"
    |> Str.replaceEach "'" "&#39;"
