xquery version "3.1";

import module namespace cc = "http://history.state.gov/ns/xquery/apps/consular-cards" at "consular-cards.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html";
declare option output:html-version "5";
declare option output:media-type "text/html";

let $all-cards := collection("/db/apps/consular-cards/data")
let $face-id := request:get-parameter("id", ())
let $face := $all-cards//tei:surface[@xml:id eq $face-id]
return

    (: Catch missing or malformed `id` parameter, temporary workaround to avoid XSS :)
    if (empty($face) or not(matches($face-id, "^c\d{4}f[1-3]$"))) then
        let $title := "Content Not Found"
        let $content := 
            <div>
                <h2>Content Not Found</h2>
                <p>No face with the requested ID was found. Please return to the homepage and try your search again.</p>
            </div>
        return
            (
                response:set-status-code(404),
                cc:wrap-html($title, $content)
            )
    else
    
let $primary-label := $face//tei:f[@name eq "label"]/tei:string/string()
let $title := "Face " || $face-id || " (“" || $primary-label || "”)"
let $card := $face/parent::tei:surfaceGrp
let $card-id := root($card)/tei:TEI/@xml:id/string()
let $content := 
    <div>
        <h2>{$title}</h2>
        <table class="table table-bordered">
            <thead>
                <tr>
                    <th>Cards</th>
                    <th>Face</th>
                </tr>
            </thead>
            <tbody>
                {
                    let $faces := $card/tei:surface
                    return
                        <tr>
                            <td>
                                <dt>Card ID</dt>
                                <dd><a href="card.xq?id={$card-id}">{$card-id}</a></dd>
                                <dt>Number of faces</dt>
                                <dd>{count($faces)}</dd>
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
                                        let $face-id := $face/@xml:id/string()
                                        let $sequence-no := $face//tei:f[@name eq "scan-sequence"]/tei:string/string()
                                        let $label := $face//tei:f[@name eq "label"]/tei:string/string()
                                        let $color := $face//tei:f[@name eq "color"]/tei:symbol/@value/string()
                                        let $status := $face//tei:f[@name eq "status"]/tei:symbol/@value/string()
                                        let $order := $face//tei:f[@name eq "order"]/tei:numeric/@value/string()
                                        let $year := $face//tei:f[@name eq "year"]/tei:string/string()
                                        let $transcription := cc:tei-to-html(root($face)//tei:div[@corresp eq "#" || $face-id]/node())
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
                                                <td>
                                                    <div id="openseadragon1" style="width: 800px; height: 600px;"></div>
                                                </td>
                                                <td style="border: 1px black solid">{$transcription}</td>
                                                <!-- 
                                                <img src="https://static.history.state.gov/consular-cards/color/medium/{$face/tei:graphic/@url => replace("\.tif", ".jpg")}"/>
                                                -->
                                                
                                            </tr>
                                        }</tbody>
                                    </table>
                                </td>
                            </tr>
                }
            </tbody>
        </table>
        <script src="/exist/apps/consular-cards/resources/openseadragon/openseadragon.min.js"/>
        <script type="text/javascript">
            OpenSeadragon({{
                id:                 "openseadragon1",
                prefixUrl:          "/exist/apps/consular-cards/resources/openseadragon/images/",
                preserveViewport:   true,
                visibilityRatio:    1,
                minZoomLevel:       1,
                defaultZoomLevel:   1,
                sequenceMode:       true,
                tileSources:   [{{
                  "@context": "http://iiif.io/api/image/2/context.json",
                  "@id": "https://ci.history.state.gov/iiif/2/{encode-for-uri("consular-cards/color/original/" || $face/tei:graphic/@url)}",
                  "height": {$face/tei:graphic/@height => substring-before("px") },
                  "width": {$face/tei:graphic/@width => substring-before("px") },
                  "profile": [ "http://iiif.io/api/image/2/level2.json" ],
                  "protocol": "http://iiif.io/api/image",
                  "tiles": [{{
                    "scaleFactors": [ 1, 2, 4, 8, 16, 32 ],
                    "width": 1024
                  }}]
                }}]
            }});
        </script>
    </div>
return
    cc:wrap-html($title, $content)