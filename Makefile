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

## Where to find the database and the views.
database := ./database
views := ./views

## Where to find some utilities.
shtpen := ./shtpen/shtpen
yaml2json := yq --output-format json
lilypond := lilypond --loglevel=warning -dno-point-and-click

## The list of dances in the database and their target names in $(website-output).
dances := $(notdir $(basename $(wildcard $(database)/dance/*.yaml)))
built_dances := $(addprefix $(website-output)/dance/, $(dances))

## The list of tunes in the database and their target names in $(website-output).
tunes := $(notdir $(basename $(wildcard $(database)/tune/*.yaml)))
built_tunes := $(addprefix $(website-output)/tune/, $(tunes))

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
	printf 'Just try `make website@docker`.\n'

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

############################################################
## Individual dances

## Generate a JSON file out of a database dance entry.
##
$(website-output)/dance/%.json: $(database)/dance/%.yaml $(website-output)/dance
	printf 'Making `dance/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a TeX file out of a dance JSON file.
##
$(website-output)/dance/%.tex: $(website-output)/dance/%.json
	printf 'Making `dance/%s.tex`... ' $*
	$(shtpen) \
	  --escape tex \
	  --json $< \
	  --raw  $(views)/tex/preamble.tex \
	  --shtp $(views)/tex/dance.tex.shtp \
	  > $@
	printf 'done.\n'

## Generate a PDF file out of a dance TeX file.
##
$(website-output)/dance/%.pdf: $(website-output)/dance/%.tex
	printf 'Making `dance/%s.pdf`... ' $*
	cd $(dir $<)
	xelatex --interaction=batchmode -halt-on-error $(notdir $<) >/dev/null
	printf 'done.\n'

## Generate a HTML file out of a dance JSON file.
##
$(website-output)/dance/%.html: $(website-output)/dance/%.json
	printf 'Making `dance/%s.html`... ' $*
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/dance.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index of dances

$(website-output)/dances.json: $(addsuffix .json, $(built_dances))
	printf 'Making `dances.json`... '
	jq -s '{dances:., root:"."}' $^ > $@
	printf 'done.\n'

$(website-output)/dances.html: $(website-output)/dances.json
	printf 'Making `dances.html`... '
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/dances.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Individual tunes

## Generate a JSON file out of a database tune entry.
##
$(website-output)/tune/%.json: $(database)/tune/%.yaml $(website-output)/tune
	printf 'Making `tune/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a LilyPond file out of a tune JSON file.
##
$(website-output)/tune/%.ly: $(website-output)/tune/%.json
	printf 'Making `tune/%s.ly`... ' $*
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
	printf 'done.\n'

## Generate a PDF file out of a tune LilyPond file.
##
$(website-output)/tune/%.pdf: $(website-output)/tune/%.ly
	printf 'Making `tune/%s.pdf`... ' $*
	cd $(dir $<)
	$(lilypond) $*
	printf 'done.\n'

## Generate a short LilyPond file out of a tune JSON file.
##
$(website-output)/tune/%.short.ly: $(website-output)/tune/%.json
	printf 'Making `tune/%s.short.ly`... ' $*
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
	printf 'done.\n'

## Generate a SVG file out of a tune short LilyPond file.
$(website-output)/tune/%.svg: $(website-output)/tune/%.short.ly
	printf 'Making `tune/%s.svg`... ' $*
	cd $(dir $<)
	$(lilypond) -dbackend=svg $*.short.ly
	inkscape --batch-process --export-area-drawing --export-plain-svg \
	  --export-filename=$*.svg $*.short.svg 2>/dev/null
	rm $*.short.svg
	printf 'done.\n'

## Generate a HTML file out of a tune JSON file.
##
$(website-output)/tune/%.html: $(website-output)/tune/%.json
	printf 'Making `tune/%s.html`... ' $*
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/tune.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index of tunes

$(website-output)/tunes.json: $(addsuffix .json, $(built_tunes))
	printf 'Making `tunes.json`... '
	jq -s '{tunes:., root:"."}' $^ > $@
	printf 'done.\n'

$(website-output)/tunes.html: $(website-output)/tunes.json
	printf 'Making `tunes.html`... '
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/tunes.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index &

$(website-output)/index.json: $(website-output)/dances.json $(website-output)/tunes.json
	printf 'Making `index.json`... '
	jq -s '{dances:.[0].dances, tunes:.[1].tunes, root:"."}' \
	  $^ \
	  > $@
	printf 'done.\n'

$(website-output)/index.html: $(website-output)/index.json
	printf 'Making `index.html`... '
	$(shtpen) \
	  --escape html \
	  --json $(website-output)/index.json \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/index.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## All

.PHONY: dances tunes index css static website

dances: $(addsuffix .html, $(built_dances)) $(addsuffix .pdf, $(built_dances)) $(website-output)/dances.html
tunes: $(addsuffix .html, $(built_tunes)) $(addsuffix .svg, $(built_tunes)) $(addsuffix .pdf, $(built_tunes)) $(website-output)/tunes.html
index: $(website-output)/index.html

css: $(website-output)
	cp $(views)/css/reset.css $(website-output)
	sassc $(views)/css/style.scss $(website-output)/style.css

static: $(website-output)
	printf 'Copying static files`... '
	cp -R $(views)/static/* $(website-output)
	printf 'done.\n'

website: dances tunes index css static

################################################################################
##   ___          _
##  |   \ ___  __| |_____ _ _
##  | |) / _ \/ _| / / -_) '_|
##  |___/\___/\__|_\_\___|_|

DOCKER_BUILDER_TAG := ghcr.io/niols/scd.niols.fr-builder:latest

.PHONY: docker-builder
docker-builder:
	printf 'Making Docker builder with tag:\n\n    %s\n\n' $(DOCKER_BUILDER_TAG)
	docker build --tag $(DOCKER_BUILDER_TAG) -f docker/builder.dockerfile .

## NOTE: We `docker cp` to `/src` and not `/wd`. Then, in the Docker container,
## we run `cp -R /src/* /wd`. This has the upside to set the permissions of
## everything in `/wd` to the user inside the Docker container, which `docker
## cp` does not do by itself.
##
## NOTE: `$(MAKEFLAGS)` contains the command-line flags given to `make`. It is
## usually passed implicitly, but we need to pass it explicitly here because of
## Docker.
##
%@docker: $(website-output)
	printf 'Running `make %s` inside Docker builder.\n' "$*"
	cid=$$(docker create $(DOCKER_BUILDER_TAG) \
	           sh -c 'cp -R /src/* . && make $* MAKEFLAGS=$(MAKEFLAGS)')
	docker cp . "$$cid":/src
	docker start --attach "$$cid"
	docker cp "$$cid":/wd/$(website-output)/. $(website-output)

################################################################################
