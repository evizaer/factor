! Copyright (C) 2005, 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel namespaces sequences words io assocs
quotations strings parser lexer arrays xml.data xml.writer debugger
splitting vectors sequences.deep combinators fry memoize ;
IN: xml.utilities

: children>string ( tag -- string )
    children>> {
        { [ dup empty? ] [ drop "" ] }
        { [ dup [ string? not ] contains? ]
          [ "XML tag unexpectedly contains non-text children" throw ] }
        [ concat ]
    } cond ;

: children-tags ( tag -- sequence )
    children>> [ tag? ] filter ;

: first-child-tag ( tag -- tag )
    children>> [ tag? ] find nip ;

: tag-named? ( name elem -- ? )
    dup tag? [ names-match? ] [ 2drop f ] if ;

: tags@ ( tag name -- children name )
    [ { } like ] dip assure-name ;

: deep-tag-named ( tag name/string -- matching-tag )
    assure-name '[ _ swap tag-named? ] deep-find ;

: deep-tags-named ( tag name/string -- tags-seq )
    tags@ '[ _ swap tag-named? ] deep-filter ;

: tag-named ( tag name/string -- matching-tag )
    assure-name swap [ tag-named? ] with find nip ;

: tags-named ( tag name/string -- tags-seq )
    tags@ swap [ tag-named? ] with filter ;

: tag-with-attr? ( elem attr-value attr-name -- ? )
    rot dup tag? [ at = ] [ 3drop f ] if ;

: tag-with-attr ( tag attr-value attr-name -- matching-tag )
    assure-name '[ _ _ tag-with-attr? ] find nip ;

: tags-with-attr ( tag attr-value attr-name -- tags-seq )
    tags@ '[ _ _ tag-with-attr? ] filter children>> ;

: deep-tag-with-attr ( tag attr-value attr-name -- matching-tag )
    assure-name '[ _ _ tag-with-attr? ] deep-find ;

: deep-tags-with-attr ( tag attr-value attr-name -- tags-seq )
    tags@ '[ _ _ tag-with-attr? ] deep-filter ;

: get-id ( tag id -- elem )
    "id" deep-tag-with-attr ;

: deep-tags-named-with-attr ( tag tag-name attr-value attr-name -- tags )
    [ deep-tags-named ] 2dip tags-with-attr ;

: assert-tag ( name name -- )
    names-match? [ "Unexpected XML tag found" throw ] unless ;

: insert-children ( children tag -- )
    dup children>> [ push-all ]
    [ swap V{ } like >>children drop ] if ;

: insert-child ( child tag -- )
    [ 1vector ] dip insert-children ;

: XML-NS:
    CREATE-WORD (( string -- name )) over set-stack-effect
    scan '[ f swap _ <name> ] define-memoized ; parsing
