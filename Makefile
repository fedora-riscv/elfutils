# Makefile for source rpm: elfutils
# $Id$
NAME := elfutils
SPECFILE = elfutils.spec

UPSTREAM_CHECKS := sig
UPSTREAM_FILES = $(NAME)-$(VERSION).tar.gz
upstream:;

define find-makefile-common
for d in common ../common ../../common ; do if [ -f $$d/Makefile.common ] ; then if [ -f $$d/CVS/Root -a -w $$/Makefile.common ] ; then cd $$d ; cvs -Q update ; fi ; echo "$$d/Makefile.common" ; break ; fi ; done
endef

MAKEFILE_COMMON := $(shell $(find-makefile-common))

ifeq ($(MAKEFILE_COMMON),)
# attept a checkout
define checkout-makefile-common
test -f CVS/Root && { cvs -Q -d $$(cat CVS/Root) checkout common && echo "common/Makefile.common" ; } || { echo "ERROR: I can't figure out how to checkout the 'common' module." ; exit -1 ; } >&2
endef

MAKEFILE_COMMON := $(shell $(checkout-makefile-common))
endif

include $(MAKEFILE_COMMON)

CURL += -k

MONOTONE = mtn

branch-portability = portable

elfutils-%.patch: elfutils-$(VERSION).tar.gz Makefile
	@rm -rf elfutils-master elfutils-$*
#	$(MONOTONE) checkout -b com.redhat.elfutils elfutils-master
	$(MONOTONE) checkout -b com.redhat.elfutils \
		    	     -r t:elfutils-$(VERSION) elfutils-master
	$(MONOTONE) checkout \
		    -b com.redhat.elfutils.$(firstword $(branch-$*) $*) \
		    elfutils-$*
	cd elfutils-master; autoreconf -i; rm -rf autom4te.cache _MTN
	cd elfutils-$*; autoreconf -i; rm -rf autom4te.cache _MTN
	diff -Nrpu elfutils-master elfutils-$* | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@

elfutils-portable.spec: elfutils.spec
	(echo '%define _with_compat 1'; sed 's/ check$$/& || :/' $<) > $@.new
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

ifeq (,$(wildcard /mnt/redhat/brewroot/packages/elfutils))
redhat = datadump.devel.redhat.com::redhat
rsync-to = devserv.devel.redhat.com:dist/elfutils/devel/systemtap-dist/
build-dep = $(portable.srpm)
else
redhat = /mnt/redhat
$(portable-build): $(portable.srpm)
	brew build $(BUILD_FLAGS) dist-$(portable-dist) $<
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
