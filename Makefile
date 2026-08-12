IMAGE := personal-website
CONTAINER := personal-website

.PHONY: build
build:
	docker build -t $(IMAGE) .

.PHONY: up
up: build
	docker run --rm -it \
		-p 4000:4000 \
		-v $(PWD):/site \
		--name $(CONTAINER) \
		$(IMAGE)
