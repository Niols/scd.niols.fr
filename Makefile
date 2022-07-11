.PHONY: help build clean docker-builder build-in-docker

################################################################################
##   _  _     _
##  | || |___| |_ __
##  | __ / -_) | '_ \
##  |_||_\___|_| .__/
##             |_|
##  The default endpoint for this endpoint is `help`, which prints a help
##  message about the other endpoints.

help:
	@printf 'Just try `make docker-builder build-in-docker`.\n'

################################################################################
##   ___      _ _    _
##  | _ )_  _(_) |__| |
##  | _ \ || | | / _` |
##  |___/\_,_|_|_\__,_|

build: clean
	@sh src/build.sh

clean:
	@rm -rf build

################################################################################
##   ___          _
##  |   \ ___  __| |_____ _ _
##  | |) / _ \/ _| / / -_) '_|
##  |___/\___/\__|_\_\___|_|

DOCKER_BUILDER_TAG := ghcr.io/niols/scd.niols.fr-builder:latest

docker-builder:
	@docker build --tag $(DOCKER_BUILDER_TAG) .

build-in-docker: clean
	@cid=$$(docker create $(DOCKER_BUILDER_TAG) make build) \
	  && docker cp . "$$cid":/wd \
	  && docker start --attach "$$cid" \
	  && docker cp "$$cid":/wd/build/. build

################################################################################
