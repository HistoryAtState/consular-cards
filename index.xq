xquery version "3.1";

import module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards" at "consular-cards.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html";
declare option output:html-version "5";
declare option output:media-type "text/html";

let $title := "Consular Cards"
let $all-cards := collection("/db/apps/consular-cards/data")
let $label := request:get-parameter("label", ())[normalize-space(.) ne ""] 
    (: strip out angle brackets to avoid XSS :)
    ! replace(., "[&lt;&gt;]", "")
let $q := request:get-parameter("q", ())[normalize-space(.) ne ""] 
    (: strip out angle brackets to avoid XSS :)
    ! replace(., "[&lt;&gt;]", "")
let $query-options := 
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>no</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite> 
    </options>
let $cards := 
    if (exists($label)) then 
        try {
            $all-cards//tei:string[ft:query(., $label, $query-options)]/ancestor::tei:surfaceGrp 
        } catch * {
            element error { "Invalid input" }
        }
    else 
        ()
let $transcription-hits := 
    if (exists($q)) then 
        try {
            $all-cards//tei:div[ft:query(., $q, $query-options)] 
        } catch * {
            element error { "Invalid input" }
        }
    else
        ()
return

    (: Catch missing or malformed `id` parameter, temporary workaround to avoid XSS :)
    if (exists($label) and empty($cards) or (exists($q) and empty($transcription-hits))) then
        let $title := "Content Not Found"
        let $content := 
            <div>
                <h2>Content Not Found</h2>
                <p>No cards with the search term were found. Please reformulate your search.</p>
            </div>
        return
            (
                response:set-status-code(404),
                cc:wrap-html($title, $content, $label, $q)
            )
    
    (: Catch invalid `q` parameter, temporary workaround to avoid XSS :)
    else if ($cards instance of element(error)) then
        let $title := "Server Error"
        let $content := 
            <div>
                <h2>Server Error</h2>
                <p>The server reported an unexpected error processing your search. Please reformulate your search, taking care to remove any special characters.</p>
            </div>
        return
            (
                response:set-status-code(500),
                cc:wrap-html($title, $content, $label, $q)
            )
    else
    
let $content := 
    if (exists($label)) then
        <div>
            <p>{count($cards)} cards found for “{$label}”, sorted alphabetically by primary label.</p>
            {
                if (exists($cards)) then 
                    <table class="table table-bordered table-striped">
                        <thead>
                            <tr>
                                <th>Label</th>
                                <th>Description</th>
                           </tr>
                        </thead>
                        <tbody>
                            {
                                for $card-g in $cards
                                let $faces := $card-g/tei:surface
                                let $labels := $faces//tei:f[@name eq "label"]/tei:string
                                let $start-years := $card-g//tei:f[@name eq "year"]/tei:string[. ne ""]
                                group by $label := $labels[1]
                                order by $label
                                return
                                    <tr>
                                        <td><a href="label.xq?label={encode-for-uri($label)}">{$label/string()}</a>
                                            {
                                                let $other-labels := $labels[. ne $label] => distinct-values()
                                                return
                                                    if (exists($other-labels)) then
                                                        <ul>{
                                                            $other-labels ! <li>{.}</li>
                                                        }</ul>
                                                    else
                                                        ()
                                            }
                                        </td>
                                        <td>{count($card-g)} cards ({count($faces)} faces) {
                                            let $min := min($start-years)
                                            let $max := max($start-years)
                                            return
                                                if ($min eq $max) then
                                                    ">" || $min
                                                else
                                                    ">" || $min || "~" || $max
                                        }</td>
                                    </tr>
                            }
                        </tbody>
                    </table>
                else
                    ()
            }
        </div>
    else if ($q) then
        <div>
            <p>{count($transcription-hits)} card faces found containing “{$q}”, sorted in original scanning sequence.</p>
            <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Cards</th>
                    <th>Face</th>
                </tr>
            </thead>
            <tbody>
                {
                    for $transcription-g in $transcription-hits
                    let $card := root($transcription-g)/tei:TEI
                    group by $card-id := $card/@xml:id/string()
                    order by $card-id
                    let $card-faces := $card//tei:surface
                    return
                        <tr>
                            <td>
                                <dt>Card ID</dt>
                                <dd><a href="card.xq?id={$card-id}">{$card-id}</a></dd>
                                <dt>Number of faces</dt>
                                <dd>{count($card-faces)}</dd>
                            </td>
                            <td>
                                <table class="table">
                                    <thead>
                                        <tr>
                                            <th>Face</th>
                                            <th>Image</th>
                                            <th>Transcription</th>
                                        </tr>
                                    </thead>
                                    <tbody>{
                                        for $transcription in $transcription-g
                                        let $face := $card-faces[@xml:id eq substring($transcription/@corresp, 2)]
                                        let $face-id := $face/@xml:id/string()
                                        let $sequence-no := $face//tei:f[@name eq "scan-sequence"]/tei:string/string()
                                        let $label := $face//tei:f[@name eq "label"]/tei:string/string()
                                        let $color := $face//tei:f[@name eq "color"]/tei:symbol/@value/string()
                                        let $status := $face//tei:f[@name eq "status"]/tei:symbol/@value/string()
                                        let $order := $face//tei:f[@name eq "order"]/tei:numeric/@value/string()
                                        let $year := $face//tei:f[@name eq "year"]/tei:string/string()
                                        let $src := 
                                            "https://static.history.state.gov/consular-cards/color/medium/"
                                            || $face/tei:graphic/@url 
                                            => replace("\.tif", ".jpg")
                                            (: 
                                            "/exist/apps/consular-cards-new/images/" || replace($face/tei:graphic/@url, "\.tif", ".jpg")
                                            :)
                                        let $transcription := cc:tei-to-html($transcription/node())
                                        return
                                            <tr>
                                                <td>
                                                    <dt>Face ID</dt>
                                                    <dd><a href="face.xq?id={$face-id}">{$face-id}</a></dd>
                                                    <dt>Sequence No.</dt>
                                                    <dd>{$sequence-no}</dd>
                                                    <dt>Label</dt>
                                                    <dd>{$label}</dd>
                                                    <dt>Color</dt>
                                                    <dd>{$color}</dd>
                                                    <dt>Status</dt>
                                                    <dd>{$status}</dd>
                                                    <dt>Order</dt>
                                                    <dd>{$order}</dd>
                                                    <dt>Start Year</dt>
                                                    <dd>{$year}</dd>
                                                </td>
                                                <td><img src="{$src}"/></td>
                                                <td style="border: 1px black solid">{$transcription}</td>
                                            </tr>
                                        }</tbody>
                                    </table>
                                </td>
                            </tr>
                }
            </tbody>
        </table>
        </div>
    else
        <div>
            <div id="about">
                <h2>About</h2>
                <p>The “Consular Cards” are a set of ~6,500 index cards that were used internally by the U.S. Department of State to track the staff of U.S. diplomatic posts abroad. The cards have been scanned and minimally indexed and reviewed by the Office of the Historian. This application provides a searchable list of the cards by label and some basic metadata about each scan. The images have not been fully transcribed, but the goal is to create a usable resource until such time as the cards can be transcribed and further enriched.</p>
                <p><strong>Update (June 5, 2024):</strong> An experimental AI-based transcription has been added, allowing a basic search of the contents of most of the ~8,600 scanned images (text extraction failed on 466, or 5%, of these, for reasons not yet known). No edits have been made.</p>
                <p>Enter a search term or <a href="labels.xq">view a list of all cards by label</a>.</p>
            </div>
            <div id="search">
                <h3>Searching the database</h3>
                <p>The database allows search within the “label” fields of each card and face thereof. By default, the database searches for all terms entered. So a search of the names field for <code>canada quebec</code> will return all records with the terms Canada AND Quebec (not necessarily in this order), not all records containing either Canada OR Quebec. To broaden the query, use the boolean <code>OR</code> operator: <code>Vietnam OR Viet</code>. The database also supports phrase searches (<code>""</code>) and wildcards (<code>?</code> for a single character, <code>*</code> for zero or more characters). Punctuation is ignored from searches.</p>
            </div>
        </div>
    
return
    cc:wrap-html($title, $content, $label, $q)