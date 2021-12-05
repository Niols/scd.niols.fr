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
      xelatex "$dance".tex
    ) > "$BUILD"/dance/"$dance"

    echo "  - generate Mustache file"
    { cat "$SRC"/html/dance.html
    } > "$BUILD"/dance/"$dance".mustache

    echo "  - compile Mustache to HTML"
    mustache \
      "$DB"/dance/"$dance"/meta.json \
      "$BUILD"/dance/"$dance".mustache \
      > "$BUILD"/dance/"$dance".html
done
