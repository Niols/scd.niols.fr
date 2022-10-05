################################################################################
##   __  __      _        __ _ _
##  |  \/  |__ _| |_____ / _(_) |___
##  | |\/| / _` | / / -_)  _| | / -_)
##  |_|  |_\__,_|_\_\___|_| |_|_\___|

## Use `help` as default target for this Makefile.
##
.DEFAULT: help

## Do not print recipes for this Makefile. We will take care of the printing
## ourselves.
##
.SILENT:

## Recipes are sent to Shell in one go, instead of line-by-line. We make sure to
## add the `-e` flag to compensate (as well as the useful `-u` and `-C`). We
## also have to add `-c` explicitly when we play with `.SHELLFLAGS`.
##
.ONESHELL:
SHELL = sh
.SHELLFLAGS = -euC -c

################################################################################
##    ___             _            _
##   / __|___ _ _  __| |_ __ _ _ _| |_ ___
##  | (__/ _ \ ' \(_-<  _/ _` | ' \  _(_-<
##   \___\___/_||_/__/\__\__,_|_||_\__/__/
##
##  This section defines constants used everywhere else in this Makefile. They
##  describe where to find files, where to put them, what utilities to use, and
##  some lists of objects gotten from the database.

## The target build directory.
output := ./_build
website-output := $(output)/website
tests-output := $(output)/tests

## Where to find the database and the views.
database := ./database
views := ./views
tests := ./tests

## Where to find some utilities.
shtpen := ./shtpen/shtpen
yaml2json := yq --output-format json
lilypond := lilypond --loglevel=warning -dno-point-and-click
inkscape := HOME=$$(mktemp -d) xvfb-run inkscape

## The list of dances in the database and their target names in $(website-output).
dances := $(notdir $(basename $(wildcard $(database)/dance/*.yaml)))
built_dances := $(addprefix $(website-output)/dance/, $(dances))

## The list of tunes in the database and their target names in $(website-output).
tunes := $(notdir $(basename $(wildcard $(database)/tune/*.yaml)))
built_tunes := $(addprefix $(website-output)/tune/, $(tunes))

## The list of books in the database and their target names in $(website-output).
books := $(notdir $(basename $(wildcard $(database)/book/*.yaml)))
built_books := $(addprefix $(website-output)/book/, $(books))

################################################################################
##   _  _     _        __        ___ _
##  | || |___| |_ __  / _|___   / __| |___ __ _ _ _
##  | __ / -_) | '_ \ > _|_ _| | (__| / -_) _` | ' \
##  |_||_\___|_| .__/ \_____|   \___|_\___\__,_|_||_|
##             |_|
##  The default endpoint for this endpoint is `help`, which prints a help
##  message about the other endpoints.

.PHONY: help clean

help:
	printf 'Just try `make website`.\n'

clean:
	printf 'Cleaning up.\n'
	rm -Rf $(output)

################################################################################
##   ___      _ _    _
##  | _ )_  _(_) |__| |
##  | _ \ || | | / _` |
##  |___/\_,_|_|_\__,_|
##
##  How to build the shape of the $(website-output) directory. The rules later on will
##  depend on this shape, unless they clearly depend on something that implies
##  that the shape already exists.

$(output):
	mkdir $(output)

$(website-output): $(output)
	mkdir $(website-output)

$(website-output)/dance: $(website-output)
	mkdir $(website-output)/dance

$(website-output)/tune: $(website-output)
	mkdir $(website-output)/tune

$(website-output)/book: $(website-output)
	mkdir $(website-output)/book

$(tests-output): $(output)
	mkdir $(tests-output)

############################################################
## Individual dances

## Generate a raw JSON file out of a database dance entry.
##
$(website-output)/dance/%.raw.json: $(database)/dance/%.yaml $(website-output)/dance
	printf 'Making `dance/%s.raw.json`...\n' $*
	cat $< | $(yaml2json) | jq '{dance:., slug:"$*"}' > $@

## Generate a JSON file out of a raw dance JSON file.
##
$(website-output)/dance/%.json: $(website-output)/dance/%.raw.json $(website-output)/all.raw.json
	printf 'Making `dance/%s.json`...\n' $*
	cat $< \
	  | jq '. + $$all + {title:(.dance.name + " | Dance"), root:".."}' \
	      --argjson all "$$(cat $(website-output)/all.raw.json)" \
	  > $@

## Generate a TeX file out of a dance JSON file.
##
$(website-output)/dance/%.tex: $(website-output)/dance/%.json
	printf 'Making `dance/%s.tex`...\n' $*
	$(shtpen) \
	  --escape tex \
	  --json $< \
	  --raw  $(views)/tex/preamble.tex \
	  --shtp $(views)/tex/dance.tex.shtp \
	  > $@

## Generate a PDF file out of a dance TeX file.
##
$(website-output)/dance/%.pdf: $(website-output)/dance/%.tex
	printf 'Making `dance/%s.pdf`...\n' $*
	cd $(dir $<)
	output=$$(
	  xelatex -halt-on-error $(notdir $<) 2>&1
	) && true
	return_code=$$?
	if [ $$return_code -ne 0 ]; then
	  printf '  => \e[1;31munexpected failure while compiling PDF\e[0m.\n'
	      printf '     Here is the output from XeLaTeX:\n'
	      printf '\n\e[37m%s\e[0m\n\n' "$$output" | sed 's|^\(.*\)|       \1|'
	  exit $$return_code
	fi

## Generate a HTML file out of a dance JSON file.
##
$(website-output)/dance/%.html: $(website-output)/dance/%.json
	printf 'Making `dance/%s.html`...\n' $*
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/dance.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

############################################################
## Index of dances

$(website-output)/dances.raw.json: $(addsuffix .raw.json, $(built_dances))
	printf 'Making `dances.raw.json`...\n'
	if [ -n '$^' ]; then
	  jq -s 'map({(.slug): (.dance)}) | .+[{}] | add | {dances:.}' $^ > $@
	else
	  printf '(Generating trivial file because there are no built dances.)\n'
	  jq -n '{dances:[]}' > $@
	fi

$(website-output)/dances.json: $(website-output)/dances.raw.json
	printf 'Making `dances.json`...\n'
	cat $< | jq '. + {root:"."}' > $@

$(website-output)/dances.html: $(website-output)/dances.json
	printf 'Making `dances.html`...\n'
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/dances.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

############################################################
## Individual tunes

## Generate a raw JSON file out of a database tune entry.
##
$(website-output)/tune/%.raw.json: $(database)/tune/%.yaml $(website-output)/tune
	printf 'Making `tune/%s.raw.json`...\n' $*
	cat $< | $(yaml2json) | jq '{tune:., slug:"$*"}' > $@

## Generate a JSON file out of a raw tune JSON file.
##
$(website-output)/tune/%.json: $(website-output)/tune/%.raw.json $(website-output)/all.raw.json
	printf 'Making `tune/%s.json`...\n' $*
	cat $< \
	  | jq '. + $$all + {title:(.tune.name + " | Tune"), root:".."}' \
	      --argjson all "$$(cat $(website-output)/all.raw.json)" \
	  > $@

## Generate a LilyPond file out of a tune JSON file.
##
$(website-output)/tune/%.ly: $(website-output)/tune/%.json
	printf 'Making `tune/%s.ly`...\n' $*
	$(shtpen) \
	  --json $< \
	  --raw  $(views)/ly/version.ly \
	  --raw  $(views)/ly/repeat-aware.ly \
	  --raw  $(views)/ly/bar-number-in-instrument-name-engraver.ly \
	  --raw  $(views)/ly/beginning-of-line.ly \
	  --raw  $(views)/ly/repeat-volta-fancy.ly \
	  --raw  $(views)/ly/preamble.ly \
	  --shtp $(views)/ly/tune.ly.shtp \
	  > $@

## Generate a PDF file out of a tune LilyPond file.
##
$(website-output)/tune/%.pdf: $(website-output)/tune/%.ly
	printf 'Making `tune/%s.pdf`...\n' $*
	cd $(dir $<)
	$(lilypond) $*

## Generate a short LilyPond file out of a tune JSON file.
##
$(website-output)/tune/%.short.ly: $(website-output)/tune/%.json
	printf 'Making `tune/%s.short.ly`...\n' $*
	$(shtpen) \
	  --json $< \
	  --raw  $(views)/ly/version.ly \
	  --raw  $(views)/ly/repeat-aware.ly \
	  --raw  $(views)/ly/bar-number-in-instrument-name-engraver.ly \
	  --raw  $(views)/ly/beginning-of-line.ly \
	  --raw  $(views)/ly/repeat-volta-fancy.ly \
	  --raw  $(views)/ly/preamble.ly \
	  --raw  $(views)/ly/preamble.short.ly \
	  --shtp $(views)/ly/tune.ly.shtp \
	  > $@

## Generate a SVG file out of a tune short LilyPond file.
$(website-output)/tune/%.svg: $(website-output)/tune/%.short.ly
	printf 'Making `tune/%s.svg`...\n' $*
	cd $(dir $<)
	$(lilypond) -dbackend=svg $*.short.ly
	$(inkscape) --batch-process --export-area-drawing --export-plain-svg \
	  --export-filename=$*.svg $*.short.svg 2>/dev/null
	rm $*.short.svg

## Generate a HTML file out of a tune JSON file.
##
$(website-output)/tune/%.html: $(website-output)/tune/%.json
	printf 'Making `tune/%s.html`...\n' $*
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/tune.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

############################################################
## Index of tunes

$(website-output)/tunes.raw.json: $(addsuffix .raw.json, $(built_tunes))
	printf 'Making `tunes.raw.json`...\n'
	if [ -n '$^' ]; then
	  jq -s 'map({(.slug): (.tune)}) | .+[{}] | add | {tunes:., root:"."}' $^ > $@
	else
	  printf '(Generating trivial file because there are no built tunes.)\n'
	  jq -n '{tunes:[], root:"."}' > $@
	fi

$(website-output)/tunes.json: $(website-output)/tunes.raw.json
	printf 'Making `tunes.json`...\n'
	cat $< | jq '. + {root:"."}' > $@

$(website-output)/tunes.html: $(website-output)/tunes.json
	printf 'Making `tunes.html`...\n'
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/tunes.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

############################################################
## Individual books

## Generate a raw JSON file out of a database book entry.
##
$(website-output)/book/%.raw.json: $(database)/book/%.yaml $(website-output)/book
	printf 'Making `book/%s.raw.json`...\n' $*
	cat $< | $(yaml2json) | jq '{book:., slug:"$*"}' > $@

## Generate a JSON file out of a raw book JSON file.
##
$(website-output)/book/%.json: $(website-output)/book/%.raw.json $(website-output)/all.raw.json
	printf 'Making `book/%s.json`...\n' $*
	cat $< \
	  | jq '. + $$all + {title:(.book.title + " | Book"), root:".."}' \
	      --argjson all "$$(cat $(website-output)/all.raw.json)" \
	  > $@

## Generate a HTML file out of a book JSON file.
##
$(website-output)/book/%.html: $(website-output)/book/%.json
	printf 'Making `book/%s.html`... ' $*
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/book.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@
	printf 'done.\n'

############################################################
## Index of books

$(website-output)/books.raw.json: $(addsuffix .raw.json, $(built_books))
	printf 'Making `books.raw.json`...\n'
	if [ -n '$^' ]; then
	  jq -s 'map({(.slug): (.book)}) | .+[{}] | add | {books:.}' $^ > $@
	else
	  printf '(Generating trivial file because there are no built books.)\n'
	  jq -n '{books:[]}' > $@
	fi

$(website-output)/books.json: $(website-output)/books.raw.json
	printf 'Making `books.json`...\n'
	cat $< | jq '. + {root:"."}' > $@

$(website-output)/books.html: $(website-output)/books.json
	printf 'Making `books.html`... '
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/books.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@
	printf 'done.\n'

############################################################
## Index &

$(website-output)/all.raw.json: $(website-output)/dances.raw.json $(website-output)/tunes.raw.json $(website-output)/books.raw.json
	printf 'Making `all.raw.json`...\n'
	jq -s '{dances:.[0].dances, tunes:.[1].tunes, books:.[2].books}' $^ > $@

$(website-output)/index.json: $(website-output)/all.raw.json
	printf 'Making `index.json`...\n'
	cat $< | jq '. + {root:"."}' > $@

$(website-output)/index.html: $(website-output)/index.json
	printf 'Making `index.html`...\n'
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/index.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

$(website-output)/non-scddb.json: $(website-output)/all.raw.json
	printf 'Making `non-scddb.json`...\n'
	cat $< | jq '. + {root:"."}' > $@

$(website-output)/non-scddb.html: $(website-output)/non-scddb.json
	printf 'Making `non-scddb.html`...\n'
	j2 $(views)/html/header.html.j2 $< > $@
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/non-scddb.html.shtp \
	  >> $@
	j2 $(views)/html/footer.html.j2 $< >> $@

############################################################
## All

.PHONY: dances tunes books index css static website

dances: $(addsuffix .html, $(built_dances)) $(addsuffix .pdf, $(built_dances)) $(website-output)/dances.html
tunes: $(addsuffix .html, $(built_tunes)) $(addsuffix .svg, $(built_tunes)) $(addsuffix .pdf, $(built_tunes)) $(website-output)/tunes.html
books: $(addsuffix .html, $(built_books)) $(website-output)/books.html
index: $(website-output)/index.html $(website-output)/non-scddb.html

css: $(website-output)
	cp $(views)/css/reset.css $(website-output)
	sassc $(views)/css/style.scss $(website-output)/style.css

static: $(website-output)
	printf 'Copying static files`...\n'
	cp -R $(views)/static/* $(website-output)

website: dances tunes books index css static

################################################################################
##   _____       _
##  |_   _|__ __| |_ ___
##    | |/ -_|_-<  _(_-<
##    |_|\___/__/\__/__/

.PHONY: test-website
test-website:
	dances=$$(yq --unwrapScalar '.build-arguments.dances.[]' $(tests)/meta.yaml)
	tunes=$$(yq --unwrapScalar '.build-arguments.tunes.[]' $(tests)/meta.yaml)
	books=$$(yq --unwrapScalar '.build-arguments.books.[]' $(tests)/meta.yaml)
	make website dances="$$dances" tunes="$$tunes" books="$$books"

.PHONY: tests
tests: $(tests-output)
	if ! [ -d $(website-output) ]; then
	  printf 'The website need to be built first for tests to run.\n'
	  exit 7
	fi

	dissimilarities=0
	unexpected_failures=0

	paths=$$(yq '.paths | length' $(tests)/meta.yaml)
	for ii in $$(seq 1 $$paths); do
	  i=$$((ii - 1))
	  path=$$(yq ".paths[$$i]" $(tests)/meta.yaml)
	  printf 'Path #%d of %d. `%s`:\n' "$$ii" "$$paths" "$$path"
	  mkdir -p "$$(dirname $(tests-output)/"$$path")"

	  viewports=$$(yq '.viewports | length' $(tests)/meta.yaml)
	  for jj in $$(seq 1 $$viewports); do
	    j=$$((jj - 1))
	    name=$$(yq ".viewports[$$j].name" $(tests)/meta.yaml)
	    width=$$(yq ".viewports[$$j].width" $(tests)/meta.yaml)
	    printf '  Viewport #%d of %d: `%s` (width: %d).\n' "$$jj" "$$viewports" "$$name" "$$width"

	    output_path="$$path"."$$width".png

	    firefox_output=$$(
	      tests/take-screenshot \
	        file://$$PWD/$(website-output)/"$$path" \
	        $(tests-output)/"$$output_path" \
	        $$width \
	        2>&1
	    ) && true

	    if [ -e $(tests-output)/"$$output_path" ]; then
	      chmod 644 $(tests-output)/"$$output_path"
	    else
	      unexpected_failures=$$((unexpected_failures + 1))
	      printf '    => \e[1;31munexpected failure while taking screenshot\e[0m.\n'
	      printf '       Here is the output from Firefox:\n'
	      printf '\n\e[37m%s\e[0m\n\n' "$$firefox_output" | sed 's|^\(.*\)|         \1|'
	      continue
	    fi

	    if ! [ -e $(tests)/outputs/"$$output_path" ]; then
	      dissimilarities=$$((dissimilarities + 1))
	      printf '    => \e[31mno reference to compare to\e[0m.\n'
	      continue
	    fi

	    diff_path="$$path"."$$width".diff.png

	    compare_output=$$(
	      compare -compose src -metric AE -format '' \
	        $(tests)/outputs/"$$output_path" $(tests-output)/"$$output_path" \
	        $(tests-output)/"$$diff_path" \
	        2>&1
	    ) && true
	    return_code=$$?

	    if [ $$return_code -eq 1 ]; then
	      dissimilarities=$$((dissimilarities + 1))
	      printf '    => \e[31mdissimilarity\e[0m.\n'
	    elif [ $$return_code -ge 2 ]; then
	      unexpected_failures=$$((unexpected_failures + 1))
	      printf '    => \e[1;31munexpected failure while comparing\e[0m.\n'
	      printf '       Here is the output from ImageMagick:\n'
	      printf '\n\e[37m%s\e[0m\n\n' "$$compare_output" | sed 's|^\(.*\)|         \1|'
	    fi
	  done
	done

	if [ $$unexpected_failures -gt 0 ]; then
	  printf 'There were \e[1;31m%d unexpected failures\e[0m.\n' "$$unexpected_failures"
	  exit 2
	fi
	if [ $$dissimilarities -gt 0 ]; then
	  printf 'There were \e[31m%d dissimilarities\e[0m.\n' "$$dissimilarities"
	  exit 1
	fi

.PHONY: promote-test-outputs
promote-test-outputs:
	if ! [ -d $(tests-output) ]; then
	  printf 'The tests need to have been run before being promoted.\n'
	  exit 7
	fi

	printf 'Promoting all the tests outputs.\n'

	paths=$$(yq '.paths | length' $(tests)/meta.yaml)
	for ii in $$(seq 1 $$paths); do
	  i=$$((ii - 1))
	  path=$$(yq ".paths[$$i]" $(tests)/meta.yaml)
	  printf '  Path #%d of %d. `%s`:\n' "$$ii" "$$paths" "$$path"
	  mkdir -p "$$(dirname $(tests)/outputs/"$$path")"

	  viewports=$$(yq '.viewports | length' $(tests)/meta.yaml)
	  for jj in $$(seq 1 $$viewports); do
	    j=$$((jj - 1))
	    name=$$(yq ".viewports[$$j].name" $(tests)/meta.yaml)
	    width=$$(yq ".viewports[$$j].width" $(tests)/meta.yaml)
	    printf '    Viewport #%d of %d: `%s` (%d).\n' "$$jj" "$$viewports" "$$name" "$$width"

	    output_path="$$path"."$$width".png

	    cp $(tests-output)/"$$output_path" $(tests)/outputs/"$$output_path"
	  done
	done
