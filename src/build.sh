#!/bin/sh
set -euC

readonly BUILD=build
readonly DB=db
readonly SRC=src

mkdir -p "$BUILD"/dance
echo "dances:"

## For each dance in the database
ls -1 "$DB"/dance | while read dance; do
    echo "- $dance"

    echo "  - generate TeX file"
    { cat "$SRC"/tex/preamble.tex
      echo '\usepackage{silence}'
      echo '\WarningsOff*'
      echo '\begin{document}'
      cat "$DB"/dance/"$dance"/descr.tex
      echo '\end{document}'
    } > "$BUILD"/dance/"$dance".tex

    echo "  - compile TeX to PDF"
    ( cd "$BUILD"/dance
      xelatex "$dance".tex \
        > "$dance".xelatex-log )

    echo "  - generate JSON file"
    { cat "$DB"/dance/"$dance"/meta.json \
      | jq "setpath([\"slug\"]; \"$dance\")"
    } > "$BUILD"/dance/"$dance".json

    echo "  - generate Mustache file"
    { cat "$SRC"/html/header.html
      cat "$SRC"/html/dance.html
      cat "$SRC"/html/footer.html
    } > "$BUILD"/dance/"$dance".mustache

    echo "  - compile Mustache to HTML"
    ( cd "$BUILD"/dance
      mustache "$dance".json "$dance".mustache \
        > "$dance".html )
    done
