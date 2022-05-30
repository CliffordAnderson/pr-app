(: =====
search-to-html.xql

Synopsis: Process faceted full-text query

Input: Model (in model namespace) supplied by search.xql

Output: HTML <section> element with search results, to be wrapped by wrapper.xql

Notes:

1. Model has three children:

a)  <m:all-content> : Filtered only by search term, but  not by any facets. Returns full counts.
b)  <m:filtered-content> : As above, but filtered by facets. Omits some items from the above, and has different counts.
c)  <m:selected-facets> : Three children: <m:selected-publishers>, <m:selected-decades>, <m:selected-years>. Used in this
    script to maintain checkbox state.
===== :)
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace hoax ="http://obdurodon.org/hoax";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace m="http://www.obdurodon.org/model";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:indent "no";

declare variable $data as document-node() := request:get-data();

declare function local:dispatch($node as node()) as item()* {
    typeswitch($node)
        (: General :)
        case text() return $node
        case element(m:count) return local:count($node)
        (: Search term :)
        case element(m:search-term) return local:search-term($node)
        (: Publishers :)
        case element(m:publishers) return local:publishers($node)
        case element(m:publisher) return local:publisher($node)
        (: Dates :)
        case element(m:data) return local:data($node)
        case element(m:decades) return local:decades($node)
        case element(m:decade) return local:decade($node)
        case element(m:month-years) return local:month-years($node)
        case element(m:month-year) return local:month-year($node)
        (: Articles:)
        case element(m:articles) return local:articles($node)
        case element(m:article) return local:article($node)
        (: Default :)
        default return local:passthru($node)
};
(: General functions:)
declare function local:data($node as element(m:data)) as element(html:section) {
    <html:section id="advanced-search">
        <html:section id="search-widgets">
            <html:form action="search" method="get">{
                for $search-area in $node/*[position() lt 4]
                return local:dispatch($search-area)
            }</html:form>
            <html:script type="text/javascript" src="resources/js/search.js"></html:script>
        </html:section>
        <html:section id="search-results">
            <html:h2>Stories</html:h2>
            {if ($node/m:articles/m:article )
            then local:dispatch($node/m:articles)
            else <html:p style="margin-left: 1em;">No matching articles found</html:p>
            }
        </html:section>
    </html:section>
};
declare function local:count($node as element(m:count)) as xs:string {
    concat(' (', $node, ')')
};
declare function local:passthru($node as node()) as item()* {
    for $child in $node/node() return local:dispatch($child)
};
(: -----
Search term functions
----- :)
declare function local:search-term($node as element(m:search-term)) as item()+ {
        <html:input id="term" name="term" type="search" placeholder="[Search term]" value="{string($node)}">{string($node)}</html:input>,
        '&#xa0;',
        <html:button type="submit">Search</html:button>
};
(: =====
Publisher functions
===== :)
declare function local:publishers($node as element(m:publishers)) as element(html:fieldset) {
    <html:fieldset>
        <html:legend>Publishers</html:legend>
        <html:ul>{local:passthru($node)}</html:ul>
    </html:fieldset>
};
declare function local:publisher($node as element(m:publisher)) as element(html:li) {
    <html:li>
        <html:label>
            <html:input type="checkbox" name="publishers[]" value="{string($node/m:label)}">{
            (: Maintain checked state :)
            if ($node/m:label = root($node)/descendant::m:selected-facets/descendant::m:publisher) 
                then attribute checked {"checked"} 
                else ()
            }</html:input>{local:passthru($node)}
        </html:label>
    </html:li>
};
(:=====
Date functions
=====:)
declare function local:decades($node as element(m:decades)) as element(html:fieldset) {
    <html:fieldset>
        <html:legend>Date</html:legend>
        <html:ul>{local:passthru($node)}</html:ul>
    </html:fieldset>
};
declare function local:decade($node as element(m:decade)) as element(html:li) {
    <html:li>
        <html:details>
            <html:summary>
                <html:label>
                    <html:input type="checkbox" class="decade-checkbox" name="decades[]" value="{string($node/m:label)}">{
                    (: Maintain checked state :)
                    if ($node/m:label = root($node)/descendant::selected-facets/descendant::m:decade) 
                        then attribute checked {"checked"} 
                        else ()
                    }</html:input> {for $child in $node/(m:label | m:count) return local:dispatch($child)}
                </html:label>
            </html:summary>
            {local:dispatch($node/m:month-years)}
        </html:details>
    </html:li>
};
declare function local:month-years($node as element(m:month-years)) as element(html:ul) {
    <html:ul>{local:passthru($node)}</html:ul>
};
declare function local:month-year($node as element(m:month-year)) as element(html:li) {
    <html:li>
        <html:label>
            <html:input type="checkbox" class="month-year-checkbox" name="month-years[]" value="{string($node/m:label)}">{
                (: Maintain checked state :)
                if ($node/m:label = root($node)/descendant::m:selected-facets/descendant::m:month-year) then attribute checked {"checked"} else ()
            }</html:input> {
            format-date($node/m:label || '-01', '[MNn] [Y] '), 
            local:count($node/m:count)
        }</html:label>
    </html:li>
};
(: =====
Article list functions
===== :)
declare function local:articles($node as element(m:articles)) as element(html:ul) {
    <html:ul>{local:passthru($node)}</html:ul>
};
declare function local:article($node as element(m:article)) as element(html:li) {
    <html:li>
        <html:a href="read?title={$node/m:id}"><html:q>{$node/m:title ! string()}</html:q></html:a>
        (<html:cite> {string-join($node/m:publisher, '; ')}</html:cite>,
        {format-date($node/m:date, '[MNn] [D], [Y]')})      
    </html:li>
};
(:=====
Main
=====:)
local:dispatch($data)