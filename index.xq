xquery version "3.1";

import module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards" at "consular-cards.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html";
declare option output:html-version "5";
declare option output:media-type "text/html";

let $title := "Consular Cards"
let $cards-doc := doc("/db/apps/consular-cards/data/consular-cards.xml")
let $q := request:get-parameter("q", ())[not(. eq "")]
let $query-options := 
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>no</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite> 
    </options>
let $cards := 
    if (exists($q)) then 
        try {
            $cards-doc//tei:string[ft:query(., $q, $query-options)]/ancestor::tei:surfaceGrp 
        } catch * {
            element error { "Invalid input" }
        }
    else 
        ()
return

    (: Catch invalid `q` parameter, temporary workaround to avoid XSS :)
    if ($cards instance of element(error)) then
        let $title := "Server Error"
        let $content := 
            <div>
                <h2>Server Error</h2>
                <p>The server reported an unexpected error processing your search. Please reformulate your search, taking care to remove any special characters.</p>
            </div>
        return
            (
                response:set-status-code(500),
                cc:wrap-html($title, $content)
            )
    else
    
let $content := 
    if (exists($q)) then
        <div>
            <p>{count($cards)} cards found for “{$q}”, sorted alphabetically by primary label.</p>
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
    else
        <div>
            <div id="about">
                <h2>About</h2>
                <p>The “Consular Cards” are a set of ~6,500 index cards that were used internally by the U.S. Department of State to track the staff of U.S. diplomatic posts abroad. The cards have been scanned and minimally indexed and reviewed by the Office of the Historian. This application provides a searchable list of the cards by label and some basic metadata about each scan. The images have not been fully transcribed, but the goal is to create a usable resource until such time as the cards can be transcribed and further enriched.</p>
                <p>Enter a search term or <a href="labels.xq">view a list of all cards by label</a>.</p>
            </div>
            <div id="search">
                <h3>Searching the database</h3>
                <p>The database allows search within the “label” fields of each card and face thereof. By default, the database searches for all terms entered. So a search of the names field for <code>canada quebec</code> will return all records with the terms Canada AND Quebec (not necessarily in this order), not all records containing either Canada OR Quebec. To broaden the query, use the boolean <code>OR</code> operator: <code>Vietnam OR Viet</code>. The database also supports phrase searches (<code>""</code>) and wildcards (<code>?</code> for a single character, <code>*</code> for zero or more characters). Punctuation is ignored from searches.</p>
            </div>
        </div>
    
return
    cc:wrap-html($title, $content)