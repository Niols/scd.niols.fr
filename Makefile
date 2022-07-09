.PHONY: build clean docker-builder build-in-docker

help:
	@printf 'Just try `make docker-builder build-in-docker`.\n'

################################################################################

build: clean
	@sh src/build.sh

clean:
	@rm -rf build

################################################################################

DOCKER_BUILDER_TAG := ghcr.io/niols/scd.niols.fr-builder:latest

docker-builder:
	@docker build --tag $(DOCKER_BUILDER_TAG) .

build-in-docker: clean
	@cid=$$(docker create $(DOCKER_BUILDER_TAG) make build) \
	  && docker cp . "$$cid":/wd \
	  && docker start --attach "$$cid" \
	  && docker cp "$$cid":/wd/build/. build

################################################################################
