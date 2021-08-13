SHELL=/bin/bash -o pipefail

REGISTRY   ?= kubedb
BIN        ?= elasticsearch-init
IMAGE      := $(REGISTRY)/$(BIN)
TAG        ?= $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

DB_IMAGE   ?= "floragunncom/sg-elasticsearch:7.13.4-52.0.0"

BUILD_DIRS := bin

$(BUILD_DIRS):
	@mkdir -p $@

.PHONY: push
push: container
	docker push $(IMAGE):$(TAG)

.PHONY: container
container: $(BUILD_DIRS)
	@rm -rf bin/.dockerfile;                                 \
	sed                                                      \
	    -e 's|{ELASTICSEARCH_IMAGE}|$(DB_IMAGE)|g'           \
	    Dockerfile.in > bin/.dockerfile;                     \
	docker build -t $(IMAGE):$(TAG) -f bin/.dockerfile .

.PHONY: version
version:
	@echo ::set-output name=version::$(TAG)

.PHONY: fmt
fmt:
	@find . -path ./vendor -prune -o -name '*.sh' -exec shfmt -l -w -ci -i 4 {} \;

.PHONY: verify
verify: fmt
	@if !(git diff --exit-code HEAD); then \
		echo "files are out of date, run make fmt"; exit 1; \
	fi

.PHONY: ci
ci: verify
