FCOS_STREAM ?= stable

nomad.ign: nomad.bu
	podman run --interactive --rm quay.io/coreos/butane:release --strict < nomad.bu > nomad.ign

firmware:
	./build-firmware.sh unpack_rpms

cache:
	@echo "Creating local cache of FCOS image"
	mkdir cache
	podman run \
		--privileged \
		--rm \
		-v .:/data \
		quay.io/coreos/coreos-installer:release \
			download \
			--architecture aarch64 \
			--stream $(FCOS_STREAM) \
			--directory /data/cache | tee ./cache/image.txt

.PHONY: install
install: nomad.ign firmware cache
ifndef TARGET_DEV
	$(error TARGET_DEV must be defined)
endif
	@echo "Installing to TARGET_DEV: $(TARGET_DEV)"
	sudo podman run \
		--privileged \
		--rm \
		-v /dev:/dev \
		-v /run/udev:/run/udev \
		-v .:/data \
		-w /data \
		quay.io/coreos/coreos-installer:release \
			install \
			--architecture aarch64 \
			--append-karg nomodeset \
			--ignition-file nomad.ign \
			--image-file $(shell cat ./cache/image.txt) \
			$(TARGET_DEV)
	./build-firmware.sh install_firmware

.PHONY: clean
clean:
	rm -rf firmware
	rm -rf cache
	rm -f nomad.ign