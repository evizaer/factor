! Copyright (C) 2010 John Benediktsson
! See https://factorcode.org/license.txt for BSD license

USING: arrays assocs combinators.short-circuit formatting
hashtables io io.streams.string kernel make math namespaces
quoting sequences splitting strings strings.parser ;

IN: ini-file

<PRIVATE

: escape ( ch -- ch' )
    H{
        { CHAR: a   CHAR: \a }
        { CHAR: b   CHAR: \b }
        { CHAR: f   CHAR: \f }
        { CHAR: n   CHAR: \n }
        { CHAR: r   CHAR: \r }
        { CHAR: t   CHAR: \t }
        { CHAR: v   CHAR: \v }
        { CHAR: '   CHAR: ' }
        { CHAR: \"  CHAR: \" }
        { CHAR: \\  CHAR: \\ }
        { CHAR: ?   CHAR: ? }
        { CHAR: ;   CHAR: ; }
        { CHAR: [   CHAR: [ }
        { CHAR: ]   CHAR: ] }
        { CHAR: =   CHAR: = }
    } ?at [ bad-escape ] unless ;

: (unescape-string) ( str -- )
    CHAR: \\ over index [
        cut-slice [ % ] dip rest-slice
        dup empty? [ "Missing escape code" throw ] when
        unclip-slice escape , (unescape-string)
    ] [ % ] if* ;

: unescape-string ( str -- str' )
    [ (unescape-string) ] "" make ;

: escape-string ( str -- str' )
    [
        [
            H{
                { CHAR: \a   "\\a"  }
                { CHAR: \b   "\\b"  }
                { CHAR: \f   "\\f"  }
                { CHAR: \n   "\\n"  }
                { CHAR: \r   "\\r"  }
                { CHAR: \t   "\\t"  }
                { CHAR: \b   "\\v"  }
                { CHAR: '    "\\'"  }
                { CHAR: \"   "\\\"" }
                { CHAR: \\   "\\\\" }
                { CHAR: ?    "\\?"  }
                { CHAR: ;    "\\;"  }
                { CHAR: [    "\\["  }
                { CHAR: ]    "\\]"  }
                { CHAR: =    "\\="  }
            } ?at [ % ] [ , ] if
        ] each
    ] "" make ;

: space? ( ch -- ? )
    "\s\t\n\r\f\v" member-eq? ;

: unspace ( str -- str' )
    [ space? ] trim ;

: unwrap ( str -- str' )
    1 swap index-of-last subseq ;

: uncomment ( str -- str' )
    ";#" [ over index [ head ] when* ] each ;

: cleanup-string ( str -- str' )
    unspace unquote unescape-string ;

SYMBOL: section
SYMBOL: option

: section? ( line -- index/f )
    {
        [ length 1 > ]
        [ first CHAR: [ = ]
        [ CHAR: ] swap last-index ]
    } 1&& ;

: line-continues? ( line -- ? )
    ?last CHAR: \ = ;

: section, ( -- )
    section get [ , ] when* ;

: option, ( name value -- )
    section get [ second swapd set-at ] [ 2array , ] if* ;

: [section] ( line -- )
    unwrap cleanup-string H{ } clone 2array section set ;

: name=value ( line -- )
    option [
        [ swap [ first2 ] dip ] [
            "=" split1 [ cleanup-string "" ] [ "" or ] bi*
        ] if*
        dup line-continues? [
            dup length 1 - head cleanup-string
            dup last space? [ " " append ] unless append 2array
        ] [
            cleanup-string append option, f
        ] if
    ] change ;

: parse-line ( line -- )
    uncomment unspace dup section? [
        section, 1 + cut [ [section] ] [ unspace ] bi*
    ] when* [ name=value ] unless-empty ;

PRIVATE>

: read-ini ( -- assoc )
    section off option off
    [ [ parse-line ] each-line section, ] { } make
    >hashtable ;

: write-ini ( assoc -- )
    [
        dup string? [
            [ escape-string ] bi@ "%s=%s\n" printf
        ] [
            [ escape-string "[%s]\n" printf ] dip
            [ [ escape-string ] bi@ "%s=%s\n" printf ]
            assoc-each nl
        ] if
    ] assoc-each ;

! FIXME: escaped comments "\;" don't work

: string>ini ( str -- assoc )
    [ read-ini ] with-string-reader ;

: ini>string ( assoc -- str )
    [ write-ini ] with-string-writer ;
