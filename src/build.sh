#!/bin/sh
set -euC

################################################################################
##   ___                             _   _
##  | _ \_ _ ___ _ __  __ _ _ _ __ _| |_(_)___ _ _
##  |  _/ '_/ -_) '_ \/ _` | '_/ _` |  _| / _ \ ' \
##  |_| |_| \___| .__/\__,_|_| \__,_|\__|_\___/_||_|
##              |_|

readonly BUILD=build
readonly DB=db
readonly OTHER=other
readonly SRC=src

## Copy CSS files
mkdir -p "$BUILD"
cp "$SRC"/css/* "$BUILD"

################################################################################
##   ___
##  |   \ __ _ _ _  __ ___ ___
##  | |) / _` | ' \/ _/ -_|_-<
##  |___/\__,_|_||_\__\___/__/
##

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

################################################################################
##   _____
##  |_   _|  _ _ _  ___ ___
##    | || || | ' \/ -_|_-<
##    |_| \_,_|_||_\___/__/
##

mkdir -p "$BUILD"/tune
printf -- 'building tunes:\n'

## For each tune in the database
ls -1 "$DB"/tune | while read tune; do
    printf -- '- %s\n' "$tune"

    printf -- '  - generate JSON file\n'
    { cat "$DB"/tune/"$tune"/meta.json \
      | jq "setpath([\"slug\"]; \"$tune\")" \
      | jq "setpath([\"root\"]; \"..\")"
    } > "$BUILD"/tune/"$tune".json

    printf -- '  - generate Mustache file\n'
    { cat "$SRC"/html/header.html
      cat "$SRC"/html/tune.html
      cat "$SRC"/html/footer.html
    } > "$BUILD"/tune/"$tune".mustache

    printf -- '  - compile Mustache to HTML\n'
    ( cd "$BUILD"/tune
      mustache "$tune".json "$tune".mustache \
        > "$tune".html )
    done

printf -- 'building tunes index:\n'
printf -- '- generate JSON file\n'
( jq -s '{tunes:., root:"."}' $(find "$BUILD"/tune -name '*.json')
) > "$BUILD"/tunes.json

printf -- '- generate Mustache file\n'
{ cat "$SRC"/html/header.html
  cat "$SRC"/html/tunes.html
  cat "$SRC"/html/footer.html
} > "$BUILD"/tunes.mustache

printf -- '- compile Mustache to HTML\n'
( cd "$BUILD"
  mustache tunes.json tunes.mustache \
    > tunes.html )

################################################################################
##   ___         _
##  |_ _|_ _  __| |_____ __
##   | || ' \/ _` / -_) \ /
##  |___|_||_\__,_\___/_\_\
##

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

################################################################################
##  __      __
##  \ \    / / _ __ _ _ __ ___ _  _ _ __
##   \ \/\/ / '_/ _` | '_ \___| || | '_ \
##    \_/\_/|_| \__,_| .__/    \_,_| .__/
##                   |_|           |_|

## Cleanup build directory
printf 'cleaning up... '
find "$BUILD" -type f -not -regex '.*.\(pdf\|html\|css\)' -delete
printf 'done\n'

printf 'copying `other` directory... '
cp -R "$OTHER" "$BUILD"/other
printf 'done\n'
