IMAGE_NAME ?= localhost/leptos-base:latest
CENTOS_BOOTC_IMAGE ?= quay.io/centos-bootc/centos-bootc:stream10
REMOTE_IMG ?= ghcr.io/s33po/leptos-base:main

.PHONY: build
build:
	podman build \
		--cap-add=all \
		--security-opt=label=type:disable \
		--device /dev/fuse \
		--pull=newer \
		--target unchunked \
		--build-arg CENTOS_BOOTC_IMAGE=$(CENTOS_BOOTC_IMAGE) \
		-f ./build/Containerfile \
		-t $(IMAGE_NAME) .

.PHONY: chunk
chunk:
	podman run --rm \
		"--mount=type=image,src=$(IMAGE_NAME),target=/chunkah" \
		-e CHUNKAH_CONFIG_STR="$$(podman inspect $(CENTOS_BOOTC_IMAGE))" \
		quay.io/coreos/chunkah build \
		--prune /sysroot/ --label ostree.commit- --label ostree.final-diffid- \
		--compressed --max-layers 256 \
		--tag "$(IMAGE_NAME)" \
		| podman load

.PHONY: run
run:
	podman run --rm -it $(IMAGE_NAME) bash

.PHONY: clean
clean:
	rm -rf ./out ./output
	podman rmi localhost/leptos-base || true
	podman image prune -f || true
