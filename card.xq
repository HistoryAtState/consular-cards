xquery version "3.1";

import module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards" at "consular-cards.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

let $cards-doc := doc("/db/apps/consular-cards/data/consular-cards.xml")
let $card-id := request:get-parameter("id", ())
let $card := $cards-doc//tei:surfaceGrp[@xml:id eq $card-id]
let $faces := $card/tei:surface
let $primary-label := $faces[1]//tei:f[@name eq "label"]/tei:string/string()
let $title := "Card " || $card-id || " (“" || $primary-label || "”)"
let $prev-card := $card/preceding-sibling::tei:surfaceGrp[1]
let $prev-card-label := $prev-card/tei:surface[1]//tei:f[@name eq "label"]/tei:string/string()
let $next-card := $card/following-sibling::tei:surfaceGrp[1]
let $next-card-label := $next-card/tei:surface[1]//tei:f[@name eq "label"]/tei:string/string()
let $content := 
    <div>
        <h2>{$title}</h2>
        <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Cards</th>
                    <th>Faces</th>
                </tr>
            </thead>
            <tbody>
                {
                    <tr>
                        <td>
                            <dt>Primary Label</dt>
                            <dd><a href="label.xq?label={encode-for-uri($primary-label)}">{$primary-label}</a></dd>
                            <dt>Card ID</dt>
                            <dd><a href="card.xq?id={$card-id}">{$card-id}</a></dd>
                            <dt>Number of faces</dt>
                            <dd>{count($faces)}</dd>
                            <dt>Navigation</dt>
                            { 
                                if ($prev-card) then 
                                    <dd><a href="card.xq?id={$prev-card/@xml:id}">Previous card</a> ({$prev-card-label})</dd> 
                                else 
                                    (),
                                if ($next-card) then 
                                    <dd><a href="card.xq?id={$next-card/@xml:id}">Next card</a> ({$next-card-label})</dd> 
                                else
                                    () 
                            }
                        </td>
                        <td>
                            <table class="table">
                                <thead>
                                    <tr>
                                        <th>Face</th>
                                        <th>Image</th>
                                    </tr>
                                </thead>
                                <tbody>{
                                    for $face in $faces
                                    let $face-id := $face/@xml:id/string()
                                    let $sequence-no := $face//tei:f[@name eq "scan-sequence"]/tei:string/string()
                                    let $label := $face//tei:f[@name eq "label"]/tei:string/string()
                                    let $color := $face//tei:f[@name eq "color"]/tei:symbol/@value/string()
                                    let $status := $face//tei:f[@name eq "status"]/tei:symbol/@value/string()
                                    let $order := $face//tei:f[@name eq "order"]/tei:numeric/@value/string()
                                    let $year := $face//tei:f[@name eq "year"]/tei:string/string()
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
                                            <td><img src="https://static.history.state.gov/consular-cards/color/medium/{$face/tei:graphic/@url => replace("\.tif", ".jpg")}"/></td>
                                        </tr>
                                    }</tbody>
                                </table>
                            </td>
                        </tr>
                }
            </tbody>
        </table>
    </div>
return
    cc:wrap-html($title, $content)