xquery version "3.1";

module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards";

declare function cc:wrap-html($title, $body) {
    let $q := request:get-parameter("q", ())
    return
    <html lang="en">
        <head>
            <!-- Required meta tags -->
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
            
            <!-- Bootstrap CSS -->
            <link href="resources/bootstrap/bootstrap.min.css" rel="stylesheet"/>
            <style type="text/css">
                body {{ font-family: HelveticaNeue, Helvetica, Arial, sans }}
                table {{ page-break-inside: avoid }}
                dl {{ margin-above: 1em }}
                dt {{ font-weight: bold }}</style>
            <style type="text/css" media="print">
                a, a:visited {{ text-decoration: underline; color: #428bca; }}
                a[href]:after {{ content: "" }}
            </style>
            <title>{$title}</title>
        </head>
        <body>
            <div class="container">
                <h3><a href="/exist/apps/consular-cards/">Consular Cards</a></h3>
                <form class="form-inline" action="/exist/apps/consular-cards/" method="get">
                    <div class="form-group"><label for="q" class="control-label">Search Card Labels</label>
                        <input type="text" name="q" id="q" class="form-control" value="{$q}"/>
                    </div>
                    <button type="submit" class="btn btn-default">Submit</button>
                </form>
                {$body}
            </div>
            <script src="resources/bootstrap/jquery.min.js"/>
            <script src="resources/bootstrap/bootstrap.min.js"/>
        </body>
    </html>
};