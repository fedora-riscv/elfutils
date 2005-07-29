# Makefile for source rpm: elfutils
# $Id: Makefile,v 1.8 2005/07/29 20:18:25 roland Exp $
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

portable: elfutils-$(VERSION)-0.$(RELEASE).src.rpm
elfutils-$(VERSION)-0.$(RELEASE).src.rpm: elfutils-portable.spec \
					  elfutils-portability.patch \
					  sources
	$(RPM_WITH_DIRS) --nodeps -bs $<
