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
	rm -Rf $(BUILD)

################################################################################
##   ___      _ _    _
##  | _ )_  _(_) |__| |
##  | _ \ || | | / _` |
##  |___/\_,_|_|_\__,_|

BUILD := build
DB := db
OTHER := other
SRC := src

DB_DANCES := $(notdir $(wildcard $(DB)/dance/*))
BUILT_DANCES := $(addprefix $(BUILD)/dance/, $(DB_DANCES))

DB_TUNES := $(notdir $(wildcard $(DB)/tune/*))
BUILT_TUNES := $(addprefix $(BUILD)/tune/, $(DB_TUNES))

shtpen := shtpen/shtpen
yaml2json := yq --output-format json

.PHONY: build-dir
build-dir:
	mkdir -p $(BUILD)

############################################################
## Individual dances

.PHONY: dance-build-dir
dance-build-dir: build-dir
	mkdir -p $(BUILD)/dance

## Generate a TeX file out of a database dance entry.
##
$(BUILD)/dance/%.tex: $(DB)/dance/%/descr.tex dance-build-dir
	printf 'Making `dance/%s.tex`... ' $*
	{ cat $(SRC)/tex/preamble.tex
	  printf -- '\\begin{document}\n'
	  cat $<
	  printf -- '\\end{document}\n'
	} > $@
	printf 'done.\n'

## Generate a PDF file out of a dance TeX file.
##
$(BUILD)/dance/%.pdf: $(BUILD)/dance/%.tex
	printf 'Making `dance/%s.pdf`... ' $*
	cd $(dir $<)
	xelatex --interaction=batchmode -halt-on-error $(notdir $<) >/dev/null
	printf 'done.\n'

## Generate a JSON file out of a database dance entry.
##
$(BUILD)/dance/%.json: $(DB)/dance/%/meta.yaml dance-build-dir
	printf 'Making `dance/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a HTML file out of a dance JSON file.
##
$(BUILD)/dance/%.html: $(BUILD)/dance/%.json dance-build-dir
	printf 'Making `dance/%s.html`... ' $*
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(SRC)/html/header.html.shtp \
	  --shtp $(SRC)/html/dance.html.shtp \
	  --shtp $(SRC)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index of dances

## NOTE: There is a missing `build-dir` dependency here, but
## it should be fine, considering this will only be called
## from other places.
$(BUILD)/dances.json: $(addsuffix .json, $(BUILT_DANCES))
	printf 'Making `dances.json`... '
	jq -s '{dances:., root:"."}' $^ > $@
	printf 'done.\n'

$(BUILD)/dances.html: $(BUILD)/dances.json build-dir
	printf 'Making `dances.html`... '
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(SRC)/html/header.html.shtp \
	  --shtp $(SRC)/html/dances.html.shtp \
	  --shtp $(SRC)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Individual tunes

.PHONY: tune-build-dir
tune-build-dir: build-dir
	mkdir -p $(BUILD)/tune

## Generate a JSON file out of a database tune entry.
##
$(BUILD)/tune/%.json: $(DB)/tune/%/meta.yaml tune-build-dir
	printf 'Making `tune/%s.json`... ' $*
	cat $< \
	  | $(yaml2json) \
	  | jq 'setpath(["slug"]; "$*")' \
	  | jq 'setpath(["root"]; "..")' \
	  > $@
	printf 'done.\n'

## Generate a HTML file out of a tune JSON file.
##
$(BUILD)/tune/%.html: $(BUILD)/tune/%.json tune-build-dir
	printf 'Making `tune/%s.html`... ' $*
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(SRC)/html/header.html.shtp \
	  --shtp $(SRC)/html/tune.html.shtp \
	  --shtp $(SRC)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index of tunes

## NOTE: There is a missing `build-dir` dependency here, but
## it should be fine, considering this will only be called
## from other places.
$(BUILD)/tunes.json: $(addsuffix .json, $(BUILT_TUNES))
	printf 'Making `tunes.json`... '
	jq -s '{tunes:., root:"."}' $^ > $@
	printf 'done.\n'

$(BUILD)/tunes.html: $(BUILD)/tunes.json build-dir
	printf 'Making `tunes.html`... '
	$(shtpen) \
	  --escape html \
	  --json $< \
	  --shtp $(SRC)/html/header.html.shtp \
	  --shtp $(SRC)/html/tunes.html.shtp \
	  --shtp $(SRC)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## Index &

$(BUILD)/index.json: $(BUILD)/dances.json $(BUILD)/tunes.json build-dir
	printf 'Making `index.json`... '
	jq -s '{tunes:.[0].tunes, dances:.[1].dances, root:"."}' \
	  $(BUILD)/tunes.json $(BUILD)/dances.json \
	  > $@
	printf 'done.\n'

$(BUILD)/index.html: $(BUILD)/index.json build-dir
	printf 'Making `index.html`... '
	$(shtpen) \
	  --escape html \
	  --json $(BUILD)/index.json \
	  --shtp $(SRC)/html/header.html.shtp \
	  --shtp $(SRC)/html/index.html.shtp \
	  --shtp $(SRC)/html/footer.html.shtp \
	  > $@
	printf 'done.\n'

############################################################
## All

.PHONY: dances tunes index css other website

dances: $(addsuffix .html, $(BUILT_DANCES)) $(addsuffix .pdf, $(BUILT_DANCES)) $(BUILD)/dances.html
tunes: $(addsuffix .html, $(BUILT_TUNES)) $(BUILD)/tunes.html
index: $(BUILD)/index.html

css: build-dir
	printf 'Copying CSS files`... '
	cp $(SRC)/css/* $(BUILD)
	printf 'done.\n'

other: build-dir
	printf 'Copying other files`... '
	cp -R $(OTHER) $(BUILD)/other
	printf 'done.\n'

website: dances tunes index css other

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
	docker cp "$$cid":/wd/$(BUILD)/. $(BUILD)

################################################################################
