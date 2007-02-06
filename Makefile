# Makefile for source rpm: elfutils
# $Id$
NAME := elfutils
SPECFILE = elfutils.spec

include ../common/Makefile.common

MONOTONE = mtn

elfutils-portability.patch: elfutils-$(VERSION).tar.gz
	@rm -rf elfutils-master elfutils-portable
	$(MONOTONE) checkout -b com.redhat.elfutils elfutils-master
	$(MONOTONE) checkout -b com.redhat.elfutils.portable elfutils-portable
	cd elfutils-master; autoreconf; rm -rf autom4te.cache _MTN
	cd elfutils-portable; autoreconf; rm -rf autom4te.cache _MTN
	diff -rpu elfutils-master elfutils-portable | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@

elfutils-portable.spec: elfutils.spec
	(echo '%define _with_compat 1'; cat $<) > $@.new
	mv -f $@.new $@

portable-r = 0.$(subst $(DIST),,$(RELEASE))
portable-vr = $(VERSION)-$(portable-r)
portable.srpm = elfutils-$(portable-vr).src.rpm
$(portable.srpm): elfutils-portable.spec elfutils-portability.patch \
		  elfutils-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) --nodeps -bs $<

portable-srpm: $(portable.srpm)

portable-dist = 3.0E-scratch
portable-build = \
	$(redhat)/brewroot/packages/elfutils/$(VERSION)/$(portable-r)

ifeq (,$(wildcard /mnt/redhat/brew/packages/elfutils))
redhat = datadump.devel.redhat.com::redhat
rsync-to = devserv.devel.redhat.com:dist/elfutils/devel/systemtap-dist/
build-dep = $(portable.srpm)
else
redhat = /mnt/redhat
$(portable-build): $(portable.srpm)
	$(BUILD_CLIENT) $(BUILD_FLAGS) dist-$(portable-dist) $<
rsync-to = $(public)
build-dep = $(portable-build)/src/$(portable.srpm)
portable-build: $(portable-build)
$(build-dep): $(portable-build)
endif

dist-files = README.elfutils systemtap-elfutils.repo
rsync-files = --exclude=tests --exclude=data $(portable-build)/
public = sources.redhat.com:/sourceware/ftp/anonftp/pub/systemtap/elfutils/

RSYNC = RSYNC_RSH=ssh rsync

systemtap-dist: $(build-dep) $(dist-files)
	@mkdir -p $@
	$(RSYNC) -a --delete --progress -v $(rsync-files) systemtap-dist/
	ln $(dist-files) systemtap-dist/
	ln -v `rpm -qlp $<` systemtap-dist/

systemtap-dist-createrepo: systemtap-dist
ifneq ($(wildcard /usr/bin/createrepo),)
	createrepo -q `cd $<; /bin/pwd`
endif

systemtap-sync: systemtap-dist-createrepo
	$(RSYNC) -az --delete --progress -v systemtap-dist/ $(rsync-to)
