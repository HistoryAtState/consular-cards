xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

declare function local:prepare-collection-col($collection-id) {
    xmldb:create-collection("/db/apps/hsg-transcribe/data", $collection-id)
};

declare function local:prepare-manifest-col($collection-id, $manifest-id) {
    local:prepare-collection-col($collection-id),
    xmldb:create-collection("/db/apps/hsg-transcribe/data/" || $collection-id, $manifest-id),
    xmldb:create-collection("/db/apps/hsg-transcribe/data/" || $collection-id || "/" || $manifest-id, "import"),
    xmldb:create-collection("/db/apps/hsg-transcribe/data/" || $collection-id || "/" || $manifest-id,  "items-info")
};

declare function local:get-collection($collection-id as xs:string) {
    let $label := "FSI/OH IIIF Collection: NARA"
    let $summary := "A IIIF collection of manifests of NARA images used by FSI/OH"
    let $_prepare := local:prepare-collection-col($collection-id)
    return
        map {
            "@context": "http://iiif.io/api/presentation/3/context.json",
            "id": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id,
            "type": "Collection",
            "label": map { "en": [ $label ] },
            "summary": map { "en": [ $summary ] },
            "requiredStatement": map {
                "label": map { "en": [ "Attribution" ] },
                "value": map { "en": [ "Images provided by NARA" ] }
            },
            "items": array {
                for $manifest-id in xmldb:get-child-collections("/db/apps/hsg-transcribe/data/" || $collection-id)
                let $manifest := local:get-manifest($collection-id, $manifest-id)
                order by $manifest-id
                return
                    map {
                        "id": $manifest?id,
                        "type": $manifest?type,
                        "label": $manifest?label,
                        "thumbnail": $manifest?thumbnail
                    }
            }
        }
};

declare function local:get-manifest($collection-id as xs:string, $manifest-id as xs:string) {
    let $_prepare := local:prepare-manifest-col($collection-id, $manifest-id)
    let $manifest-col := "/db/apps/hsg-transcribe/data/" || $collection-id || "/" || $manifest-id
    let $nara-record-file := $manifest-col || "import/nara-record.json"
    let $import-col := $manifest-col || "/import"
    let $nara-record-file := $import-col || "/nara-record.json"
    let $nara-record-json :=
        if (util:binary-doc-available($nara-record-file)) then
            json-doc($nara-record-file)
        else
            let $json-text := unparsed-text("https://catalog.archives.gov/proxy/records/search?naId_is=" || $manifest-id)
            let $_store := xmldb:store($import-col, "nara-record.json", $json-text)
            return
                json-doc($nara-record-file)
    let $hit := $nara-record-json?body?hits?hits?*
    let $record-id := $hit?_id
    let $record := $hit?_source?record
    let $ancestors := $record?ancestors?*?title
    let $objects := $record?digitalObjects?*
    let $items := 
        for $object at $n in $objects
        let $objectFilename := $object?objectFilename
        let $objectUrl := $object?objectUrl
        let $items-info-col := $manifest-col || "/items-info"
        let $item-json-filename := $objectFilename || "_info.json"
        let $item-json-file := $items-info-col || "/" || $item-json-filename
        let $item-json :=
            if (util:binary-doc-available($item-json-file)) then
                json-doc($item-json-file)
            else
                let $json-url :=
                    "https://catalog.archives.gov/iiif/3/"
                    || encode-for-uri(substring-after($objectUrl, "https://s3.amazonaws.com/NARAprodstorage/"))
                    || "/info.json"
                let $json-text := unparsed-text($json-url)
(:                let $json-text := unparsed-text("https://catalog.archives.gov/iiif/3/lz%2Fdc-metro%2Frg-059%2F302031%2FT172%2FT172-09%2F" || $objectFilename || "/info.json"):)
                let $_store := xmldb:store($items-info-col, $item-json-filename, $json-text)
(:                let $_wait := util:wait(1000):)
                return
                    json-doc($item-json-file)
        return
            map {
                "id": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id || "/" || $manifest-id || "/canvas-" || $n,
                "type": "Canvas",
                "label": map { "none": [ "Canvas " || $n ] },
                "height": $item-json?height,
                "width": $item-json?width,
                "items": [
                    map {
                        "id": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id || "/" || $manifest-id || "/canvas-" || $n || "/p1",
                        "type": "AnnotationPage",
                        "items": array {
                            map {
                                "id": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id || "/" || $manifest-id || "/canvas-" || $n || "/p1/a1",
                                "type": "Annotation",
                                "motivation": "painting",
                                "body": map {
                                    "id": replace($item-json?id, "^http://alb-prod-1862687368.us-east-1.elb.amazonaws.com:8182/", "https://catalog.archives.gov/") || "/full/max/0/default.jpg",
                                    "type": "Image",
                                    "label": map { "en": [ "Image " || $n ] },
                                    "format": "image/jpeg",
                                    "profile": $item-json?profile,
                                    "width": $item-json?width,
                                    "height": $item-json?height
                                },
                                "target": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id || "/" || $manifest-id || "/canvas-" || $n
                            }
                        }
                    }
                ]
            }
    return
        map {
            "id": "https://labs.history.state.gov/exist/apps/consular-cards/iiif/" || $collection-id || "/" || $manifest-id,
            "type": "Manifest",
            "label": 
                map { 
                    "en": [ 
                        string-join(
                            (
                                "NARA",
                                $record?microformPublications?1?title,
                                $record?physicalOccurrences?1?mediaOccurrences?1?containerId, 
                                $record?title 
                            ),
                            " / "
                        )
                    ] 
                },
            "thumbnail": [
                map {
                    "id": replace($items[1]?items?1?items?1?body?id, "/full/max/0/default.jpg$", "/full/150,/0/default.jpg"),
                    "type": "Image",
                    "format": "image/jpeg"
                }
            ],
            "requiredStatement": map {
                "label": map { "en": [ "Attribution" ] },
                "value": map { "en": [ "Images provided by NARA" ] }
            },
            "items": array { $items }
        }
};

let $response-header := 
    (
        response:set-header("Access-Control-Allow-Origin", "*"),
        response:set-header("Content-Type", "application/json")
    )
let $collection-id := request:get-parameter("collection-id", ())[. ne ""]
let $manifest-id := request:get-parameter("manifest-id", ())[. ne ""]
return
    if (exists($collection-id) and exists($manifest-id)) then
        local:get-manifest($collection-id, $manifest-id)
    else if (exists($collection-id)) then
        local:get-collection($collection-id)
    else
        (
            response:set-status-code(404),
            map { 
                "status": "missing required collection-id (hint: add 'nara' to the URL)"
            }
        )