#!/usr/bin/make -f

SHELL:=$(shell which bash)

# determine how to call docker depending on whether user is in docker group
DOCKER_NEEDS_SUDO:=$(shell ((id -G -n | tr " " "\n" | grep -qP '^docker$$') && echo -n false) || echo -n true)

ifeq ($(DOCKER_NEEDS_SUDO),true)
DOCKER:=sudo $(shell which docker)
else
DOCKER:=$(shell which docker)
endif

# docker arguments
DOCKER_ORG:=naftulikay
DOCKER_REPO:=fuzzy-datetime
DOCKER_TAG:=latest
DOCKER_IMAGE:=$(DOCKER_ORG)/$(DOCKER_REPO):$(DOCKER_TAG)

# docker build args
DOCKER_BUILD_ARG_RUST_STRIP_BINARY:=false
DOCKER_BUILD_ARG_RUST_AUDITABLE_BINARY:=true
DOCKER_BUILD_ARG_RUST_RUN_TESTS:=true
DOCKER_BUILD_ARG_RUST_RUN_AUDIT:=true

.PHONY: init docker

docker:
	@$(DOCKER) build -t "$(DOCKER_IMAGE)" \
		--build-arg "RUST_AUDITABLE_BINARY=$(DOCKER_BUILD_ARG_RUST_AUDITABLE_BINARY)" \
		--build-arg "RUST_STRIP_BINARY=$(DOCKER_BUILD_ARG_STRIP_BINARY)" \
		--build-arg "RUST_RUN_AUDIT=$(DOCKER_BUILD_ARG_RUST_RUN_AUDIT)" \
		--build-arg "RUST_RUN_TESTS=$(DOCKER_BUILD_ARG_RUST_RUN_TESTS)" \
		./