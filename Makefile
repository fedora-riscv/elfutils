# Makefile for source rpm: elfutils
# $Id: Makefile,v 1.5 2005/07/21 09:09:19 roland Exp $
NAME := elfutils
SPECFILE = $(firstword $(wildcard *.spec))

TARGETS += elfutils-portability.patch

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
