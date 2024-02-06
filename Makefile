SHELL := /usr/bin/bash -e -f

SRC_DIR := $(shell echo $$PWD)
BUILD_DIR := $(SRC_DIR)/build
BUILD_DIR_SRC := $(BUILD_DIR)/src
BUILD_DIR_OUT := $(BUILD_DIR)/output
DOCKER_OUT := $(BUILD_DIR)/docker_out
PACKAGES_OUT_DIR := $(SRC_DIR)/packages

VERSION := $(shell git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')

default:
	@$(EDITOR) Makefile


# building section
copy_files:
	install -dm 0755 "$(BUILD_DIR_SRC)/usr/bin/"
	install -m 0755 ./pmtud-bh-workaround.sh "$(BUILD_DIR_SRC)/usr/bin/pmtud-bh-workaround"

	install -dm 0755 "$(BUILD_DIR_SRC)/usr/lib/systemd/system/"
	install -m 0644 ./systemd/pmtud-bh-workaround@.service "$(BUILD_DIR_SRC)/usr/lib/systemd/system/"

	install -dm 0755 "$(BUILD_DIR_SRC)/usr/share/licenses/pmtud-bh-workaround"
	install -m 0644 ./LICENSE.md "$(BUILD_DIR_SRC)/usr/share/licenses/pmtud-bh-workaround/LICENSE.md"

	install -dm 0755 "$(BUILD_DIR_SRC)/usr/share/man/man1"
	@{ \
		echo -e ".TH man 1 \"$$(LANG='C' date  +"%d %b %Y")\" \"$(VERSION)\" \"pmtud-bh-workaround\""; \
		echo -e ".SH NAME\npmtud-bh-workaround"; \
		echo -e ".SH README"; \
		cat README.md; \
		echo -e ".SH AUTHOR\nAndrei V <andrei@ptaxa.net>"; \
		echo -e ".SH LICENSE\nMIT /usr/share/licenses/pmtud-bh-workaround/LICENSE.md"; \
		echo -e ".SH GITHUB\nhttps://github.com/PtaxLaine/pmtud-bh-workaround"; \
		echo -e ".SH VERSION\n$(VERSION)"; \
	} | \
	gzip -c > "$(BUILD_DIR_SRC)/usr/share/man/man1/pmtud-bh-workaround.1.gz"

build: copy_files
	@mkdir -p "$(BUILD_DIR_OUT)" && \
	mkdir -p "$(PACKAGES_OUT_DIR)" && \
	tar -cpv --zstd --owner=0 --group=0 -f "$(BUILD_DIR_OUT)/pmtud-bh-workaround.tar.zst" -C "$(BUILD_DIR_SRC)" .

clean:
	@git clean -ixd


# installing section
check_dependencies:
	@if [ "$$NO_CHECK_DEPENDECIES" = "" ]; then \
		_="$$( /usr/bin/gzip --help )" && \
		_="$$( /usr/bin/gawk --help )" && \
		_="$$( /usr/bin/whois --help )" && \
		_="$$( /usr/bin/ip --help )" && \
		>&2 echo "no dependencies errors found"; \
	fi;

install: build check_dependencies
	tar -xf "$(BUILD_DIR_OUT)/pmtud-bh-workaround.tar.zst" -C /
	[[ -f "/usr/bin/systemctl" ]] && /usr/bin/systemctl daemon-reload

uninstall:
	rm -f /usr/bin/pmtud-bh-workaround

	rm -f /usr/lib/systemd/system/pmtud-bh-workaround@.service

	rm -f /usr/share/man/man1/pmtud-bh-workaround.1.gz
	rm -rf /usr/share/licenses/pmtud-bh-workaround

	rm -rf /var/cache/pmtud-bh-workaround

	[[ -f "/usr/bin/systemctl" ]] && /usr/bin/systemctl daemon-reload

	@notremoved=$$( find /etc/systemd/system -name 'pmtud-bh-workaround@*' ) && \
	if [[ "$$notremoved" != "" ]]; then \
		>&2 echo -e "WARNGING!\nNext files wasn't removed:\n===============\n$$notremoved\n==============\n" ; \
	fi;


# packaging section
package: build docker

sign: package
	@if [ "$$GPGKEY" = "" ]; then \
		>&2 echo '`$$GPGKEY` env. variable must be set'; \
		exit 1; \
	fi;
	gpg -u $$GPGKEY --detach-sign $(PACKAGES_OUT_DIR)/generic-pmtud-bh-workaround-$(VERSION)-any.tar.zst
	gpg -u $$GPGKEY --detach-sign $(PACKAGES_OUT_DIR)/archlinux-pmtud-bh-workaround-$(VERSION)-any.pkg.tar.zst
	gpg -u $$GPGKEY --detach-sign $(PACKAGES_OUT_DIR)/debian-pmtud-bh-workaround-$(VERSION)-any.deb


# dockerizing section
docker: docker_arch docker_debian
	cp "$(BUILD_DIR_OUT)/pmtud-bh-workaround.tar.zst" "$(PACKAGES_OUT_DIR)/generic-pmtud-bh-workaround-$(VERSION)-any.tar.zst";

docker_arch:
	@if [ "$$PACKAGER" = "" ]; then \
		>&2 echo '`$$PACKAGER` env. variable must be set'; \
		exit 1; \
	fi; \
		\
	mkdir -p "$(DOCKER_OUT)" && \
	mkdir -p "$(PACKAGES_OUT_DIR)" && \
		\
	TAG="pmtud.bh.workaround/archlinux-builder"; \
	docker build --tag "$$TAG" "docker/ArchLinux" && \
	docker run --rm -v "$$PWD:/sources" -v "$(DOCKER_OUT):/output" --env PACKAGER="$$PACKAGER" "$$TAG" && \
	cp "$(DOCKER_OUT)/pmtud-bh-workaround.pkg.tar.zst" "$(PACKAGES_OUT_DIR)/archlinux-pmtud-bh-workaround-$(VERSION)-any.pkg.tar.zst";

docker_debian:
	@if [ "$$DEBMAINTAINER" = "" ]; then \
		if [ "$$DEBEMAIL" = "" ] || [ "$$DEBFULLNAME" = "" ]; then \
			>&2 echo 'env. variable `$$DEBMAINTAINER` or (`$$DEBEMAIL` and `$$DEBFULLNAME`) must be set'; \
			exit 1; \
		fi; \
		DEBMAINTAINER="$$DEBFULLNAME \<$$DEBEMAIL\>"; \
	fi; \
		\
	mkdir -p "$(DOCKER_OUT)" && \
	mkdir -p "$(PACKAGES_OUT_DIR)" && \
		\
	TAG="pmtud.bh.workaround/debian-builder"; \
	docker build --tag "$$TAG" "docker/Debian" && \
	docker run --rm -v "$$PWD:/sources" -v "$(DOCKER_OUT):/output" --env DEBMAINTAINER="$$DEBMAINTAINER" -it "$$TAG" && \
	cp "$(DOCKER_OUT)/pmtud-bh-workaround.deb" "$(PACKAGES_OUT_DIR)/debian-pmtud-bh-workaround-$(VERSION)-any.deb";
