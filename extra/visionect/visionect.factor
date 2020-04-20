! Copyright (C) 2020 John Benediktsson
! See http://factorcode.org/license.txt for BSD license
USING: accessors assocs base64 calendar calendar.format
checksums.hmac checksums.sha combinators formatting http
http.client json.reader json.writer kernel math.parser
namespaces sequences ;
IN: visionect

SYMBOL: visionect-base-url
visionect-base-url [ "http://localhost:8081" ] initialize

SYMBOL: visionect-api-key

SYMBOL: visionect-api-secret

<PRIVATE

: visionect-authorization ( verb date path -- auth )
    "%s\n\n\n%s\n%s" sprintf visionect-api-secret get sha-256
    hmac-bytes >base64 visionect-api-key get ":" rot 3append ;

: set-visionect-headers ( request -- request )
    now timestamp>http-string "Date" set-header
    dup [ method>> ] [ "Date" header ] [ url>> path>> ] tri
    visionect-authorization "Authorization" set-header ;

: visionect-request ( request -- data )
    set-visionect-headers http-request nip ;

: visionect-url ( path -- url )
    visionect-base-url get prepend ;

: visionect-get ( path -- data )
    visionect-url <get-request> visionect-request ;

: visionect-put ( post-data path -- data )
    visionect-url <put-request> visionect-request ;

: visionect-delete ( path -- data )
    visionect-url <delete-request> visionect-request ;

: visionect-post ( post-data path -- data )
    visionect-url <post-request> visionect-request ;

PRIVATE>

! ## DEVICES

: get-device ( uuid -- device )
    "/api/device/" prepend visionect-get "" like json> ;

: update-device ( device -- )
    dup "Uuid" of "/api/device/" prepend visionect-put drop ;

: remove-device ( uuid -- )
    "/api/device/" prepend visionect-delete drop ;

: all-devices ( -- devices )
    "/api/device/" visionect-get "" like json> ;

: update-devices ( devices -- )
    json> "/api/device/" visionect-put drop ;

: tclv-list ( uuid -- tclv )
    "/api/devicetclv/" prepend visionect-get "" like json> ;

: get-tclv ( uuid type -- config )
    [ "/api/cmd/Param/" prepend ] dip
    "{\"Data\": [{\"Type\": %d, \"Control\": 0, \"Value\": \"\"}]}"
    sprintf swap visionect-post "" like json> ;

: set-tclv ( uuid type value -- config )
    [ "/api/cmd/Param/" prepend ] 2dip
    "{\"Data\": [{\"Type\": %d, \"Control\": 1, \"Value\": \"%s\"}]}"
    sprintf swap visionect-post "" like json> ;

: reboot-device ( uuid -- )
    f swap "/api/device/" "/reboot" surround visionect-post drop ;

: reboot-devices ( uuids -- )
    >json "/api/device/reboot" visionect-post drop ;

! ## SESSIONS

: get-session ( uuid -- session )
    "/api/session/" prepend visionect-get "" like json> ;

: update-session ( session -- )
    dup "Uuid" of "/api/session/" prepend visionect-put drop ;

: remove-session ( uuid -- )
    "/api/session/" prepend visionect-delete drop ;

: all-sessions ( -- sessions )
    "/api/session/" visionect-get "" like json> ;

: create-session ( session -- )
    "/api/session/" visionect-post drop ;

: update-sessions ( sessions -- )
    >json "/api/session/" visionect-put drop ;

: restart-session ( uuid -- )
    "/api/session/" "/restart" surround visionect-get drop ;

: restart-sessions ( uuids -- )
    >json "/api/session/restart" visionect-post drop ;

! ## USERS

: get-user ( username -- user )
    "/api/user/" prepend visionect-get "" like json> ;

: update-user ( user -- )
    dup "Username" of "/api/user/" prepend visionect-put drop ;

: remove-user ( username -- )
    "/api/user/" prepend visionect-delete drop ;

: all-users ( -- users )
    "/api/user/" visionect-get "" like json> ;

: create-user ( user -- )
    >json "/api/user/" visionect-post drop ;

: update-users ( users -- )
    >json "/api/user/" visionect-put drop ;

! ## CONFIG

: get-config ( -- config )
    "/api/config/" visionect-get "" like json> ;

: update-config ( config -- )
    >json "/api/config/" visionect-put drop ;

! ## LIVE VIEW

: live-view ( uuid cached? -- png )
    [ "/api/live/device/" ] 2dip
    "/cached.png" "/image.png" ? 3append
    visionect-get ;

! ## DEVICE STATUS

: device-status ( uuid -- status )
    "/api/devicestatus/" prepend visionect-get "" like json> ;

: device-status-range ( uuid from to group? -- status )
    [ [ timestamp>unix-time ] bi@ ] [ "true" "false" ? ] bi*
    "%s?%s,%s,%s" sprintf device-status ;

! ## BACKENDS

: http-backend ( png uuid -- )
    "/backend/" prepend visionect-put drop ;