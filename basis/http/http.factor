! Copyright (C) 2003, 2010 Slava Pestov.
! See https://factorcode.org/license.txt for BSD license.
USING: accessors arrays ascii assocs base64 calendar calendar.format
calendar.parser combinators hashtables http.parsers io io.crlf
io.encodings.iana io.encodings.utf8 kernel make math math.parser
mime.types present sequences sets sorting splitting urls ;
IN: http

CONSTANT: max-redirects 10

: (read-header) ( -- alist )
    [ read-?crlf dup f like ] [ parse-header-line ] produce nip ;

: collect-headers ( assoc -- assoc' )
    H{ } clone [ '[ _ push-at ] assoc-each ] keep ;

: process-header ( alist -- assoc )
    f swap [ [ swap or dup ] dip swap ] assoc-map nip
    collect-headers [ "; " join ] assoc-map
    >hashtable ;

: read-header ( -- assoc )
    (read-header) process-header ;

: header-value>string ( value -- string )
    {
        { [ dup timestamp? ] [ timestamp>http-string ] }
        { [ dup array? ] [ [ header-value>string ] map "; " join ] }
        [ present ]
    } cond ;

: check-header-string ( str -- str )
    ! https://en.wikipedia.org/wiki/HTTP_Header_Injection
    dup "\r\n" intersects?
    [ "Header injection attack" throw ] when ;

: write-header ( assoc -- )
    sort-keys [
        [ check-header-string write ": " write ]
        [ header-value>string check-header-string write crlf ] bi*
    ] assoc-each crlf ;

TUPLE: cookie name value version comment path domain expires max-age http-only secure ;

: <cookie> ( value name -- cookie )
    cookie new
        swap >>name
        swap >>value ;

: parse-set-cookie ( string -- seq )
    [
        f swap
        (parse-set-cookie)
        [
            swapd pick >lower {
                { "version" [ >>version ] }
                { "comment" [ >>comment ] }
                { "expires" [ [ cookie-string>timestamp >>expires ] unless-empty ] }
                { "max-age" [ string>number seconds >>max-age ] }
                { "domain" [ >>domain ] }
                { "path" [ >>path ] }
                { "httponly" [ drop t >>http-only ] }
                { "secure" [ drop t >>secure ] }
                [ drop rot <cookie> dup , ]
            } case nip
        ] assoc-each
        drop
    ] { } make ;

: parse-cookie ( string -- seq )
    [
        f swap
        (parse-cookie)
        [
            swap {
                { "$version" [ >>version ] }
                { "$domain" [ >>domain ] }
                { "$path" [ >>path ] }
                [ <cookie> dup , nip ]
            } case
        ] assoc-each
        drop
    ] { } make ;

: check-cookie-string ( string -- string' )
    dup "=;'\"\r\n" intersects?
    [ "Bad cookie name or value" throw ] when ;

: unparse-cookie-value ( key value -- )
    {
        { f [ drop ] }
        { t [ check-cookie-string , ] }
        [
            {
                { [ dup timestamp? ] [ timestamp>cookie-string ] }
                { [ dup duration? ] [ duration>seconds number>string ] }
                { [ dup real? ] [ number>string ] }
                [ ]
            } cond
            [ check-cookie-string ] bi@ "=" glue ,
        ]
    } case ;

: check-cookie-value ( string -- string )
    [ "Cookie value must not be f" throw ] unless* ;

: (unparse-cookie) ( cookie -- strings )
    [
        dup name>> check-cookie-string
        over value>> check-cookie-value unparse-cookie-value
        "$path" over path>> unparse-cookie-value
        "$domain" over domain>> unparse-cookie-value
        drop
    ] { } make ;

: unparse-cookie ( cookies -- string )
    [ (unparse-cookie) ] map concat "; " join ;

: unparse-set-cookie ( cookie -- string )
    [
        dup name>> check-cookie-string
        over value>> check-cookie-value unparse-cookie-value
        "path" over path>> unparse-cookie-value
        "domain" over domain>> unparse-cookie-value
        "expires" over expires>> unparse-cookie-value
        "max-age" over max-age>> unparse-cookie-value
        "httponly" over http-only>> unparse-cookie-value
        "secure" over secure>> unparse-cookie-value
        drop
    ] { } make "; " join ;

TUPLE: request
    method
    url
    proxy-url
    version
    header
    post-data
    cookies
    redirects ;

: set-header ( request/response value key -- request/response )
    pick header>> set-at ;

: basic-auth ( username password -- str )
    ":" glue >base64 "Basic " "" prepend-as ;

: set-basic-auth ( request username password -- request )
    basic-auth "Authorization" set-header ;

: set-proxy-basic-auth ( request username password -- request )
    basic-auth "Proxy-Authorization" set-header ;

: <request> ( -- request )
    request new
        "1.1" >>version
        <url>
            H{ } clone >>query
        >>url
        <url> >>proxy-url
        H{ } clone >>header
        V{ } clone >>cookies
        "close" "Connection" set-header
        "Factor http.client" "User-Agent" set-header
        max-redirects >>redirects ;

: header ( request/response key -- value )
    swap header>> at ;

! https://github.com/factor/factor/issues/2273
! https://observatory.mozilla.org/analyze/factorcode.org
! https://csp-evaluator.withgoogle.com/?csp=https://factorcode.org
: add-modern-headers ( response -- response )
    "max-age=63072000; includeSubDomains; preload" "Strict-Transport-Security" set-header
    "nosniff" "X-Content-Type-Options" set-header
    "default-src https: 'unsafe-inline'; frame-ancestors 'none'; object-src 'none'; img-src 'self' data:;" "Content-Security-Policy" set-header
    "DENY" "X-Frame-Options" set-header
    "1; mode=block" "X-XSS-Protection" set-header ;

TUPLE: response
    version
    code
    message
    header
    cookies
    content-type
    content-charset
    content-encoding
    body ;

: <response> ( -- response )
    response new
        "1.1" >>version
        H{ } clone >>header
        "close" "Connection" set-header
        now timestamp>http-string "Date" set-header
        "Factor http.server" "Server" set-header
        ! XXX: add-modern-headers
        utf8 >>content-encoding
        V{ } clone >>cookies ;

M: response clone
    call-next-method
        [ clone ] change-header
        [ clone ] change-cookies ;

: get-cookie ( request/response name -- cookie/f )
    [ cookies>> ] dip '[ [ _ ] dip name>> = ] find nip ;

: delete-cookie ( request/response name -- )
    over cookies>> [ get-cookie ] dip remove! drop ;

: put-cookie ( request/response cookie -- request/response )
    [ name>> dupd get-cookie [ dupd delete-cookie ] when* ] keep
    over cookies>> push ;

TUPLE: raw-response
    version
    code
    message
    body ;

: <raw-response> ( -- response )
    raw-response new
        "1.1" >>version ;

TUPLE: post-data data params content-type content-encoding ;

: <post-data> ( content-type -- post-data )
    post-data new
        swap >>content-type ;

: parse-content-type-attributes ( string -- attributes )
    split-words harvest [
        "=" split1
        "\"" ?head drop "\"" ?tail drop
    ] { } map>assoc ;

: parse-content-type ( content-type -- type encoding )
    ";" split1
    parse-content-type-attributes "charset" of
    [ dup mime-type-encoding encoding>name ] unless* ;
