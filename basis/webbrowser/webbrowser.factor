! Copyright (C) 2011 John Benediktsson
! See https://factorcode.org/license.txt for BSD license
USING: accessors command-line io.pathnames kernel namespaces
sequences strings system ui.operations urls vocabs ;
IN: webbrowser

HOOK: open-item os ( item -- )

"webbrowser." os name>> append require

: open-url ( url -- )
    >url open-item ;

PREDICATE: url-string < string >url protocol>> >boolean ;

[ pathname? ] \ open-item H{ } define-operation
[ [ url? ] [ url-string? ] bi or ] \ open-url H{ } define-operation

: webbrowser-main ( -- )
    command-line get [ open-url ] each ;

MAIN: webbrowser-main
