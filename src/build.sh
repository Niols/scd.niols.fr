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

    printf -- '  - generate HTML file\n'
    "$SRC"/shhtml \
      --json "$BUILD"/dance/"$dance".json \
      --shhtml "$SRC"/html/header.html.sh \
      --shhtml "$SRC"/html/dance.html.sh \
      --shhtml "$SRC"/html/footer.html.sh \
      > "$BUILD"/dance/"$dance".html
    done

printf -- 'building dances index:\n'
printf -- '- generate JSON file\n'
( jq -s '{dances:., root:"."}' $(find "$BUILD"/dance -name '*.json')
) > "$BUILD"/dances.json

printf -- '- generate HTML file\n'
"$SRC"/shhtml \
  --json "$BUILD"/dances.json \
  --shhtml "$SRC"/html/header.html.sh \
  --shhtml "$SRC"/html/dances.html.sh \
  --shhtml "$SRC"/html/footer.html.sh \
  > "$BUILD"/dances.html

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

    printf -- '  - generate HTML file\n'
    "$SRC"/shhtml \
      --json "$BUILD"/tune/"$tune".json \
      --shhtml "$SRC"/html/header.html.sh \
      --shhtml "$SRC"/html/tune.html.sh \
      --shhtml "$SRC"/html/footer.html.sh \
      > "$BUILD"/tune/"$tune".html
    done

printf -- 'building tunes index:\n'
printf -- '- generate JSON file\n'
( jq -s '{tunes:., root:"."}' $(find "$BUILD"/tune -name '*.json')
) > "$BUILD"/tunes.json

printf -- '- generate HTML file\n'
"$SRC"/shhtml \
  --json "$BUILD"/tunes.json \
  --shhtml "$SRC"/html/header.html.sh \
  --shhtml "$SRC"/html/tunes.html.sh \
  --shhtml "$SRC"/html/footer.html.sh \
  > "$BUILD"/tunes.html

################################################################################
##   ___         _
##  |_ _|_ _  __| |_____ __
##   | || ' \/ _` / -_) \ /
##  |___|_||_\__,_\___/_\_\
##

printf 'building index:\n'

printf -- '- generate JSON file\n'
printf -- '{"root":"."}' > "$BUILD"/index.json

printf -- '- generate HTML file\n'
"$SRC"/shhtml \
  --json "$BUILD"/index.json \
  --shhtml "$SRC"/html/header.html.sh \
  --shhtml "$SRC"/html/index.html.sh \
  --shhtml "$SRC"/html/footer.html.sh \
  > "$BUILD"/index.html

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
