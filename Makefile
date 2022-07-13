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
build := ./build

## Where to find the database and the views.
database := ./database
views := ./views

## Where to find some utilities.
shtpen := ./shtpen/shtpen
yaml2json := yq --output-format json

## The list of dances in the database and their target names in $(build).
dances := $(notdir $(basename $(wildcard $(database)/dance/*.yaml)))
built_dances := $(addprefix $(build)/dance/, $(dances))

## The list of tunes in the database and their target names in $(build).
tunes := $(notdir $(basename $(wildcard $(database)/tune/*.yaml)))
built_tunes := $(addprefix $(build)/tune/, $(tunes))

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
	rm -Rf $(build)

################################################################################
##   ___      _ _    _
##  | _ )_  _(_) |__| |
##  | _ \ || | | / _` |
##  |___/\_,_|_|_\__,_|

.PHONY: build-dir
build-dir:
	mkdir -p $(build)

############################################################
## Individual dances

.PHONY: dance-build-dir
dance-build-dir: build-dir
	mkdir -p $(build)/dance

## Generate a JSON file out of a database dance entry.
##
$(build)/dance/%.json: $(database)/dance/%.yaml dance-build-dir
	printf 'Making `dance/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a TeX file out of a dance JSON file.
##
$(build)/dance/%.tex: $(build)/dance/%.json dance-build-dir
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
$(build)/dance/%.pdf: $(build)/dance/%.tex
	printf 'Making `dance/%s.pdf`... ' $*
	cd $(dir $<)
	xelatex --interaction=batchmode -halt-on-error $(notdir $<) >/dev/null
	printf 'done.\n'

## Generate a HTML file out of a dance JSON file.
##
$(build)/dance/%.html: $(build)/dance/%.json dance-build-dir
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

## NOTE: There is a missing `build-dir` dependency here, but
## it should be fine, considering this will only be called
## from other places.
$(build)/dances.json: $(addsuffix .json, $(built_dances))
	printf 'Making `dances.json`... '
	jq -s '{dances:., root:"."}' $^ > $@
	printf 'done.\n'

$(build)/dances.html: $(build)/dances.json build-dir
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

.PHONY: tune-build-dir
tune-build-dir: build-dir
	mkdir -p $(build)/tune

## Generate a JSON file out of a database tune entry.
##
$(build)/tune/%.json: $(database)/tune/%.yaml tune-build-dir
	printf 'Making `tune/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a HTML file out of a tune JSON file.
##
$(build)/tune/%.html: $(build)/tune/%.json tune-build-dir
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

## NOTE: There is a missing `build-dir` dependency here, but
## it should be fine, considering this will only be called
## from other places.
$(build)/tunes.json: $(addsuffix .json, $(built_tunes))
	printf 'Making `tunes.json`... '
	jq -s '{tunes:., root:"."}' $^ > $@
	printf 'done.\n'

$(build)/tunes.html: $(build)/tunes.json build-dir
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

$(build)/index.json: $(build)/dances.json $(build)/tunes.json build-dir
	printf 'Making `index.json`... '
	jq -s '{tunes:.[0].tunes, dances:.[1].dances, root:"."}' \
	  $(build)/tunes.json $(build)/dances.json \
	  > $@
	printf 'done.\n'

$(build)/index.html: $(build)/index.json build-dir
	printf 'Making `index.html`... '
	$(shtpen) \
	  --escape html \
	  --json $(build)/index.json \
	  --shtp $(views)/html/header.html.shtp \
	  --shtp $(views)/html/index.html.shtp \
	  --shtp $(views)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## All

.PHONY: dances tunes index static website

dances: $(addsuffix .html, $(built_dances)) $(addsuffix .pdf, $(built_dances)) $(build)/dances.html
tunes: $(addsuffix .html, $(built_tunes)) $(build)/tunes.html
index: $(build)/index.html

static: build-dir
	printf 'Copying static files`... '
	cp -R $(views)/static/* $(build)
	printf 'done.\n'

website: dances tunes index static

################################################################################
##   ___          _
##  |   \ ___  __| |_____ _ _
##  | |) / _ \/ _| / / -_) '_|
##  |___/\___/\__|_\_\___|_|

DOCKER_BUILDER_TAG := ghcr.io/niols/scd.niols.fr-builder:latest

.PHONY: docker-builder
docker-builder:
	printf 'Making Docker builder with tag:\n\n    %s\n\n' $(DOCKER_BUILDER_TAG)
	docker build --tag $(DOCKER_BUILDER_TAG) .

## NOTE: The dependency in `clean` is mandatory so as to avoid permissions
## errors. It has to do with the use of `docker cp` not giving the right
## permissions to what has been copied.
##
## NOTE: `$(MAKEFLAGS)` contains the command-line flags given to `make`. It is
## usually passed implicitly, but we need to pass it explicitly here because of
## Docker.
##
%@docker: clean
	printf 'Running `make %s` inside Docker.\n' "$*"
	cid=$$(docker create $(DOCKER_BUILDER_TAG) make $* MAKEFLAGS=$(MAKEFLAGS))
	docker cp . "$$cid":/wd
	docker start --attach "$$cid"
	docker cp "$$cid":/wd/$(build)/. $(build)

################################################################################
