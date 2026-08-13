IMAGE := personal-website
CONTAINER := personal-website

RUBY_VERSION := $(shell cat .ruby-version)

.PHONY: build
build:
	docker build \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) \
		-t $(IMAGE) .

.PHONY: up
up: build
	docker run --rm -it \
		-p 4000:4000 \
		-v $(PWD):/site \
		--name $(CONTAINER) \
		$(IMAGE)
