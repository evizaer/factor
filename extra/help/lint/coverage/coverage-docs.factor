USING: help help.lint.coverage help.lint.coverage.private
help.markup help.syntax io kernel sequences strings vocabs words ;
IN: help.lint.coverage

<PRIVATE
: $related-subsections ( element -- )
    [ related-words ] [ $subsections ] bi ;
PRIVATE>

ABOUT: "help.lint.coverage"

ARTICLE: "help.lint.coverage" "Help coverage linting"
"The " { $vocab-link "help.lint.coverage" } " vocabulary implements a very picky documentation completeness checker."
$nl
"The documentation coverage linter requires most words to have " { $link POSTPONE: HELP: } " declarations defining some of the "
{ $links $values $description $error-description $class-description $examples } " sections (see " { $links "element-types" } ")."
$nl
"This vocabulary is intended to be used alongside and after " { $vocab-link "help.lint" } ", not as a replacement for it."
$nl
"These words are provided to aid in writing more complete documentation:"
{ $related-subsections
    word-help-coverage.
    vocab-help-coverage.
    prefix-help-coverage.
}

"Coverage report objects:"
{ $related-subsections
    word-help-coverage
    help-coverage.
}

"Raw report generation:"
{ $related-subsections
    <word-help-coverage>
    <vocab-help-coverage>
    <prefix-help-coverage>
} ;

{ word-help-coverage word-help-coverage. <word-help-coverage> <vocab-help-coverage> <prefix-help-coverage> }
related-words

HELP: word-help-coverage
{ $class-description "A documentation coverage report for a single word." } ;

HELP: help-coverage.
{ $values { "coverage" word-help-coverage } }
{ $contract "Displays a coverage object." }
{ $examples
    { $example
        "USING: help.lint.coverage ;"
        "\\ <word-help-coverage> <word-help-coverage> help-coverage."
        "[help.lint.coverage] <word-help-coverage>: full help coverage"
    }
} ;

HELP: word-help-coverage.
{ $values { "word-spec" { $or word string } } }
{ $description "Prettyprints a help coverage report of " { $snippet "word-spec" } " to " { $link output-stream } "." }
{ $examples
    { $example
        "USING: sequences help.lint.coverage ;"
        "\\ map word-help-coverage."
        "[sequences] map: needs help section: $examples"
    }
} ;

HELP: vocab-help-coverage.
{ $values { "vocab-spec" { $or vocab string } } }
{ $description "Prettyprints a help coverage report of " { $snippet "vocab-spec" } " to " { $link output-stream } "." }
{ $examples
    { $example
        "USING: help.lint.coverage ;"
        "\"english\" vocab-help-coverage."
"[english] a10n: needs help sections: $description $examples
[english] count-of-things: needs help sections: $description $examples
[english] pluralize: needs help sections: $description $examples
[english] singularize: needs help sections: $description $examples

0.0% of words have complete documentation"
    }
} ;

HELP: prefix-help-coverage.
{ $values { "prefix-spec" { $or vocab string } } { "private?" boolean } }
{ $description "Prettyprints a help coverage report of " { $snippet "prefix-spec" } " to " { $link output-stream } "." }
{ $examples
    { $example
        "USING: help.lint.coverage ;"
        "\"english\" t prefix-help-coverage."
"[english] a10n: needs help sections: $description $examples
[english] count-of-things: needs help sections: $description $examples
[english] pluralize: needs help sections: $description $examples
[english] singularize: needs help sections: $description $examples
[english.private] match-case: needs help sections: $description $examples
[english.private] plural-to-singular: needs help sections: $description $examples
[english.private] singular-to-plural: needs help sections: $description $examples

0.0% of words have complete documentation"
    }
} ;

HELP: <prefix-help-coverage>
{ $values { "prefix" string } { "private?" boolean } { "coverage" sequence } }
{ $description "Runs the help coverage checker on every child vocabulary of the given " { $snippet "prefix" } ", including the base vocabulary. If " { $snippet "private?" } " is " { $snippet "f" } ", the prefix's child " { $snippet ".private" } " vocabularies are not checked. If " { $snippet "private?" } " is " { $snippet "t" } ", " { $emphasis "all" } " child vocabularies are checked." }
{ $examples
    { $example
        "USING: help.lint.coverage prettyprint ;"
        "\"english\" t <prefix-help-coverage> ."
"{
    T{ word-help-coverage
        { word-name a10n }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name count-of-things }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name pluralize }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name singularize }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name match-case }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name plural-to-singular }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name singular-to-plural }
        { omitted-sections { $description $examples } }
    }
}"
    }
} ;

HELP: <word-help-coverage>
{ $values { "word" { $or string word } } { "coverage" word-help-coverage } }
{ $contract "Looks up a word in the current scope and generates a documentation coverage report for it."}
{ $examples
    { $example
        "USING: help.lint.coverage prettyprint ;"
        "\\ <word-help-coverage> <word-help-coverage> ."
"T{ word-help-coverage
    { word-name <word-help-coverage> }
    { 100%-coverage? t }
}"
    }
} ;

HELP: <vocab-help-coverage>
{ $values { "vocab-spec" { $or vocab string } } { "coverage" sequence } }
{ $description "Runs the help coverage checker on the vocabulary in the given " { $snippet "vocab-spec" } "." }
{ $examples
    { $example
        "USING: help.lint.coverage prettyprint ;"
        "\"english\" <vocab-help-coverage> ."
"{
    T{ word-help-coverage
        { word-name a10n }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name count-of-things }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name pluralize }
        { omitted-sections { $description $examples } }
    }
    T{ word-help-coverage
        { word-name singularize }
        { omitted-sections { $description $examples } }
    }
}"
    }
} ;