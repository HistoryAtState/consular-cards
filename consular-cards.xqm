xquery version "3.1";

module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function cc:tei-to-html($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return $node
            case element(tei:head) return element h4 { attribute style { "text-align: center" }, cc:tei-to-html($node/node()) }
            case element(tei:table) return element table { attribute class { "table table-bordered" }, cc:tei-to-html($node/node()) }
            case element(tei:row) return element tr { cc:tei-to-html($node/node()) }
            case element(tei:cell) return 
                if ($node/parent::tei:row/@role eq "label") then 
                    element th { cc:tei-to-html($node/node()) }
                else
                    element td { cc:tei-to-html($node/node()) }
            case element(tei:p) return element p { attribute style { "text-align: center" }, cc:tei-to-html($node/node()) }
            case element(tei:lb) return element br { cc:tei-to-html($node/node()) }
            case element(tei:unclear) return element span { attribute style { "color: red" }, cc:tei-to-html($node/node()) }
            default return serialize($node, map {"indent": true()})
};

declare function cc:wrap-html($title as xs:string, $body as element()) {
    cc:wrap-html($title, $body, (), ())
};

declare function cc:wrap-html($title as xs:string, $body as element(), $label as xs:string?, $q as xs:string?) {
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
            <div class="container-fluid">
                <h3><a href="/exist/apps/consular-cards/">Consular Cards</a></h3>
                <form class="form-inline" action="/exist/apps/consular-cards/" method="get">
                    <div class="form-group"><label for="label" class="control-label">Search Card Labels</label>
                        <input type="text" name="label" id="label" class="form-control" value="{$label}"/>
                    </div>
                    <div class="form-group"><label for="q" class="control-label">Search Card Transcriptions</label>
                        <input type="text" name="q" id="q" class="form-control" value="{$q}"/>
                    </div>
                    <a href="?" class="btn btn-default">Clear</a>
                    <button type="submit" class="btn btn-primary">Submit</button>
                </form>
                {$body}
            </div>
            <script src="resources/bootstrap/jquery.min.js"/>
            <script src="resources/bootstrap/bootstrap.min.js"/>
        </body>
    </html>
};