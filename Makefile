# Makefile for source rpm: elfutils
# $Id: Makefile,v 1.4 2005/06/09 22:29:12 roland Exp $
NAME := elfutils
SPECFILE = $(firstword $(wildcard *.spec))

TARGETS += elfutils-portability.patch

include ../common/Makefile.common

master-cvsroot = :gserver:cvs.devel.redhat.com:/cvs/devel

elfutils-portability.patch: elfutils-$(VERSION).tar.gz
	@rm -rf elfutils-master elfutils-portable
	cvs -d $(master-cvsroot) -Q export \
	    -d elfutils-master -r HEAD elfutils/elfutils
	cvs -d $(master-cvsroot) -Q export \
	    -d elfutils-portable -r portable-branch elfutils/elfutils
	cd elfutils-master; autoreconf; rm -rf autom4te.cache
	cd elfutils-portable; autoreconf; rm -rf autom4te.cache
	diff -rpu elfutils-master elfutils-portable | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@
