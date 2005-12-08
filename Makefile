# Makefile for source rpm: elfutils
# $Id$
NAME := elfutils
SPECFILE = elfutils.spec

include ../common/Makefile.common

MONOTONE = monotone

elfutils-portability.patch: elfutils-$(VERSION).tar.gz
	@rm -rf elfutils-master elfutils-portable
	$(MONOTONE) checkout -b com.redhat.elfutils elfutils-master
	$(MONOTONE) checkout -b com.redhat.elfutils.portable elfutils-portable
	cd elfutils-master; autoreconf; rm -rf autom4te.cache MT
	cd elfutils-portable; autoreconf; rm -rf autom4te.cache MT
	diff -rpu elfutils-master elfutils-portable | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@

elfutils-portable.spec: elfutils.spec
	(echo '%define _with_compat 1'; cat $<) > $@.new
	mv -f $@.new $@

portable-vr = $(VERSION)-0.$(RELEASE)
portable.srpm = elfutils-$(portable-vr).src.rpm
$(portable.srpm): elfutils-portable.spec elfutils-portability.patch \
		  elfutils-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) --nodeps -bs $<

portable-srpm: $(portable.srpm)

portable-dist = 3.0E-scratch
portable-beehive = $(redhat)/dist/$(portable-dist)/elfutils/$(portable-vr)

ifeq (,$(wildcard /mnt/redhat/dist/.))
redhat = datadump.devel.redhat.com::redhat
rsync-to = devserv.devel.redhat.com:dist/elfutils/devel/systemtap-dist/
beehive-dep =
else
redhat = /mnt/redhat
$(portable-beehive): $(portable.srpm)
	$(BHC_CLIENT) $(BHC_FLAGS) dist-$(portable-dist) $<
rsync-to = $(public)
beehive-dep = $(portable-beehive)
portable-build: $(portable-beehive)
endif

dist-files = README.elfutils systemtap-elfutils.repo \
	     elfutils-$(VERSION).tar.gz elfutils-portability.patch
rsync-files = --exclude=tests $(portable-beehive)/
public = sources.redhat.com:/sourceware/ftp/anonftp/pub/systemtap/elfutils/

RSYNC = RSYNC_RSH=ssh rsync

systemtap-dist: $(beehive-dep) $(dist-files)
	@mkdir -p $@
	$(RSYNC) -a --delete --progress -v $(rsync-files) systemtap-dist/
	ln $(dist-files) systemtap-dist/

systemtap-dist-createrepo: systemtap-dist
ifneq ($(wildcard /usr/bin/createrepo),)
	createrepo -q $<
endif

systemtap-sync: systemtap-dist-createrepo
	$(RSYNC) -az --delete --progress -v systemtap-dist/ $(rsync-to)
