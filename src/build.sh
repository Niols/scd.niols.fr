#!/bin/sh
set -euC

readonly BUILD=build
readonly DB=db
readonly OTHER=other
readonly SRC=src

## Copy CSS files
mkdir -p "$BUILD"
cp "$SRC"/css/* "$BUILD"

mkdir -p "$BUILD"/dance
printf -- 'building dances:\n'

## For each dance in the database
ls -1 "$DB"/dance | while read dance; do
    printf -- '- %s\n' "$dance"

    printf -- '  - generate TeX file\n'
    { cat "$SRC"/tex/preamble.tex
      printf -- '\\begin{document}\n'
      cat "$DB"/dance/"$dance"/descr.tex
      printf -- '\\end{document}\n'
    } > "$BUILD"/dance/"$dance".tex

    printf -- '  - compile TeX to PDF\n'
    ( cd "$BUILD"/dance
      xelatex "$dance".tex \
        > "$dance".xelatex-log )

    printf -- '  - generate JSON file\n'
    { cat "$DB"/dance/"$dance"/meta.json \
      | jq "setpath([\"slug\"]; \"$dance\")" \
      | jq "setpath([\"root\"]; \"..\")"
    } > "$BUILD"/dance/"$dance".json

    printf -- '  - generate Mustache file\n'
    { cat "$SRC"/html/header.html
      cat "$SRC"/html/dance.html
      cat "$SRC"/html/footer.html
    } > "$BUILD"/dance/"$dance".mustache

    printf -- '  - compile Mustache to HTML\n'
    ( cd "$BUILD"/dance
      mustache "$dance".json "$dance".mustache \
        > "$dance".html )
    done

printf -- 'building dances index:\n'
printf -- '- generate JSON file\n'
( jq -s '{dances:., root:"."}' $(find "$BUILD"/dance -name '*.json')
) > "$BUILD"/dances.json

printf -- '- generate Mustache file\n'
{ cat "$SRC"/html/header.html
  cat "$SRC"/html/dances.html
  cat "$SRC"/html/footer.html
} > "$BUILD"/dances.mustache

printf -- '- compile Mustache to HTML\n'
( cd "$BUILD"
  mustache dances.json dances.mustache \
    > dances.html )

printf 'building index:\n'

printf -- '{"root":"."}' > "$BUILD"/index.json

printf -- '- generate Mustache file\n'
{ cat "$SRC"/html/header.html
  cat "$SRC"/html/index.html
  cat "$SRC"/html/footer.html
} > "$BUILD"/index.mustache

printf -- '- compile Mustache to HTML\n'
( cd "$BUILD"
  mustache index.json index.mustache \
    > index.html )

## Cleanup build directory
printf 'cleaning up... '
find "$BUILD" -type f -not -regex '.*.\(pdf\|html\|css\)' -delete
printf 'done\n'

printf 'copying `other` directory... '
cp -R "$OTHER" "$BUILD"/other
printf 'done\n'
