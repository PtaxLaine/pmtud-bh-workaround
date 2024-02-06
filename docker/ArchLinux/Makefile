SHELL := /usr/bin/bash
BUILD_DIR := /tmp/build

default: prepare
	@cd $(BUILD_DIR) && \
	PKGEXT=".pkg.tar.zst" \
	makepkg -f --nodeps --nosign --noconfirm && \
	mv *.pkg.tar.zst /output/pmtud-bh-workaround.pkg.tar.zst

prepare:
	@mkdir $(BUILD_DIR) && \
	cd $(BUILD_DIR) && \
	cp -arx /sources/. . && \
	cp -arx ./docker/ArchLinux/build_rules/* . ;
