VERSION := $(shell cat ./Dockerfile | head -n 1 | sed -e 's/^.*://')
S9PK_PATH=$(shell find . -name photoview.s9pk -print)

.DELETE_ON_ERROR:

all: verify

verify:  photoview.s9pk $(S9PK_PATH)
	embassy-sdk verify $(S9PK_PATH)

install: photoview.s9pk
	appmgr install photoview.s9pk

photoview.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md
	embassy-sdk pack

image.tar: Dockerfile docker_entrypoint.sh
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/photoview --platform=linux/arm64 -o type=docker,dest=image.tar .

manifest.yaml: Dockerfile
	yq e -i '.version = "$(VERSION)"' manifest.yaml
