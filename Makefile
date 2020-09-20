SHELL=/bin/bash -o pipefail

REGISTRY   ?= kubedb
BIN        := elasticsearch-init
IMAGE      := $(REGISTRY)/$(BIN)
TAG        := $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")

ES_BIN        := elasticsearch
ES_IMAGE      := $(REGISTRY)/$(ES_BIN)
ES_TAG        := 7.9.1-xpack

.PHONY: push
push: container
	docker push $(IMAGE):$(TAG)

.PHONY: container
container:
	@sed															\
	    -e 's|{ELASTICSEARCH_IMAGE}|$(ES_IMAGE):$(ES_TAG)|g'		\
	    Dockerfile.in > Dockerfile;
	docker build -t $(IMAGE):$(TAG) .

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
