ASSETS := $(shell yq e '.assets.[].src' manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION := $(shell cat ./Dockerfile | head -n 1 | sed -e 's/^.*://')
# HELLO_WORLD_SRC := $(shell find ./hello-world/src) hello-world/Cargo.toml hello-world/Cargo.lock

.DELETE_ON_ERROR:

all: photoview.s9pk

install: photoview.s9pk
	appmgr install photoview.s9pk

photoview.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md $(ASSET_PATHS)
	appmgr -vv pack $(shell pwd) -o photoview.s9pk
	appmgr -vv verify photoview.s9pk

instructions.md: README.md
	cp README.md instructions.md

image.tar: Dockerfile docker_entrypoint.sh
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/photoview --platform=linux/arm/v7 -o type=docker,dest=image.tar .

manifest.yaml: hello-world/Cargo.toml
	yq e -i '.version = $(VERSION)' manifest.yaml
