xquery version "3.1";

import module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards" at "consular-cards.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

let $title := "All Labels"
let $cards-doc := doc("/db/apps/consular-cards/data/consular-cards.xml")
let $cards := $cards-doc//tei:surfaceGrp
let $content :=
    <div class="container">
        <h2>{$title}</h2>
        <table class="table table-bordered">
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
    </div>
return
    cc:wrap-html($title, $content)
