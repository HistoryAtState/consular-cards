xquery version "3.1";

import module namespace console = "http://exist-db.org/xquery/console";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


if ($exist:path eq "") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if ($exist:path eq "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="index.xq"/>
    </dispatch>

else if (starts-with($exist:path, "/iiif/")) then
    let $params := $exist:path => substring-after("/iiif/") => tokenize("/")
    let $collection-id := $params[1]
    let $manifest-id := $params[2]
    let $canvas-id := $params[3]
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/iiif.xq">
                <add-parameter name="collection-id" value="{$collection-id}"/>
                <add-parameter name="manifest-id" value="{$manifest-id}"/>
                <add-parameter name="canvas-id" value="{$canvas-id}"/>
            </forward>
        </dispatch>

else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>