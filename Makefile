VERSION := $(shell cat ./Dockerfile | head -n 1 | sed -e 's/^.*://')
EMVER := $(shell yq e ".version" manifest.yaml)
S9PK_PATH=$(shell find . -name photoview.s9pk -print)

.DELETE_ON_ERROR:

all: verify

verify:  photoview.s9pk $(S9PK_PATH)
	embassy-sdk verify $(S9PK_PATH)

install: photoview.s9pk
	embassy-cli package install photoview.s9pk

photoview.s9pk: manifest.yaml image.tar instructions.md LICENSE icon.png
	embassy-sdk pack

image.tar: Dockerfile docker_entrypoint.sh
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/photoview/main:${EMVER} --platform=linux/arm64/v8 -o type=docker,dest=image.tar .