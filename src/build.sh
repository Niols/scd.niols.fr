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
    { cat "$SRC"/preamble.tex
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
done
