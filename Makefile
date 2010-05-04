# Makefile for source rpm: elfutils
# $Id$
NAME := elfutils
SPECFILE = elfutils.spec

all:

UPSTREAM_CHECKS := sig
UPSTREAM_FILES = $(NAME)-$(VERSION).tar.bz2
upstream:;

define find-makefile-common
for d in common ../common ../../common ; do if [ -f $$d/Makefile.common ] ; then if [ -f $$d/CVS/Root -a -w $$d/Makefile.common ] ; then cd $$d ; cvs -Q update ; fi ; echo "$$d/Makefile.common" ; break ; fi ; done
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

ifneq (,$(CURL))
CURL += -k
endif

patches := $(patsubst %,elfutils-%.patch,robustify portability)
all: $(patches)

branch-portability = portable

git-%/configure: .git/refs/heads/* Makefile
	@rm -rf $(@D)
	git archive --prefix=$(@D)/ $(firstword $(branch-$*) $*) | tar xf -
	cd $(@D) && autoreconf -i && rm -rf autom4te.cache

elfutils-%.patch: git-%/configure
	branch=$(firstword $(branch-$*) $*); \
	master=`git merge-base origin/master $$branch` && \
	master=`git describe --tags --always $$master` && \
	(set -x; $(MAKE) git-$$master/configure) && \
	(set -x; diff --exclude='.gitignore' -Nrpu git-$$master $(<D)) | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@

elfutils-portable.spec: elfutils.spec
	(echo '%define _with_compat 1'; sed 's/ check$$/& || :/' $<) > $@.new
	mv -f $@.new $@

portable-r = 0.$(subst $(DIST),,$(RELEASE))
portable-vr = $(VERSION)-$(portable-r)
portable.srpm = elfutils-$(portable-vr).src.rpm
$(portable.srpm): elfutils-portable.spec $(patches) \
		  elfutils-$(VERSION).tar.bz2
	$(RPM_WITH_DIRS) --nodeps -bs $<

portable-srpm: $(portable.srpm)
