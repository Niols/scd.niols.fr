#!/bin/sh
set -euC

readonly BUILD=build
readonly DB=db
readonly SRC=src

## Copy CSS files
mkdir -p "$BUILD"
cp "$SRC"/css/* "$BUILD"

mkdir -p "$BUILD"/dance
echo "building dances:"

## For each dance in the database
ls -1 "$DB"/dance | while read dance; do
    echo "- $dance"

    echo "  - generate TeX file"
    { cat "$SRC"/tex/preamble.tex
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
      | jq "setpath([\"slug\"]; \"$dance\")" \
      | jq "setpath([\"root\"]; \"..\")"
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

echo 'building dances index:'
echo '- generate JSON file'
( jq -s '{dances:., root:"."}' $(find "$BUILD"/dance -name '*.json')
) > "$BUILD"/dances.json

echo '- generate Mustache file'
{ cat "$SRC"/html/header.html
  cat "$SRC"/html/dances.html
  cat "$SRC"/html/footer.html
} > "$BUILD"/dances.mustache

echo '- compile Mustache to HTML'
( cd "$BUILD"
  mustache dances.json dances.mustache \
    > dances.html )

## Cleanup build directory
printf 'cleaning up... '
find "$BUILD" -type f -not -regex '.*.\(pdf\|html\|css\)' -delete
printf 'done\n'
