SHELL := /usr/bin/bash
BUILD_DIR := /tmp/build

default: gen_git_versions templatizer
	@cd $(BUILD_DIR) && \
	dpkg-buildpackage -b --no-sign && \
	mv /tmp/pmtud-bh-workaround_*.deb /output/pmtud-bh-workaround.deb

prepare:
	@mkdir $(BUILD_DIR) && \
	cd $(BUILD_DIR) && \
	cp -arx /sources/. . && \
	cp -arx ./docker/Debian/build_rules/debian .

templatizer:
	@cd $(BUILD_DIR) && \
	sed -i "s/{{DEBMAINTAINER}}/$$DEBMAINTAINER/g" debian/control ;

gen_git_versions: prepare
	@cd $(BUILD_DIR) && \
	git log --format=format:"pmtud-bh-workaround (%(describe:tags)) unstable; urgency=medium%n%n  * %s%n%n -- %aN <%aE>  %aD%n" | sed -e 's/^pmtud-bh-workaround (v/pmtud-bh-workaround (/g' \
		> debian/changelog
