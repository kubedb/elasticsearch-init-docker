SHELL=/bin/bash -o pipefail

REGISTRY   ?= kubedb
BIN        := es-init
IMAGE      := $(REGISTRY)/$(BIN)
TAG        := 0.0.2

.PHONY: push
push: container
	docker push $(IMAGE):$(TAG)

.PHONY: container
container:
	docker build -t $(IMAGE):$(TAG) .

.PHONY: version
version:
	@echo ::set-output name=version::$(TAG)