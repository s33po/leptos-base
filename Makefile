IMAGE_NAME ?= localhost/leptos-base:latest
REMOTE_IMG ?= ghcr.io/s33po/leptos-base:main

.PHONY: podman-build
podman-build:
	podman build \
		--cap-add=all \
		--security-opt=label=type:disable \
		--device /dev/fuse \
		--pull=newer \
		-f ./build/Containerfile \
		-t $(IMAGE_NAME) .

.PHONY: buildah-build
buildah-build:
	buildah build \
		--cap-add=all \
		--security-opt=label=type:disable \
		--skip-unused-stages=false \
		--device /dev/fuse \
		--pull=newer \
		-f ./build/Containerfile \
		-t $(IMAGE_NAME) .

.PHONY: chunkah
chunkah:
	podman run --rm \
		"--mount=type=image,src=$(IMAGE_NAME),target=/chunkah" \
		-e CHUNKAH_CONFIG_STR="$$(podman inspect $(IMAGE_NAME))" \
		quay.io/coreos/chunkah build \
		--prune /sysroot/ --label ostree.commit- --label ostree.final-diffid- \
		--compressed --max-layers 128 \
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
