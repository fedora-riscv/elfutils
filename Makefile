# Makefile for source rpm: elfutils
# $Id: Makefile,v 1.3 2005/05/10 05:57:44 roland Exp $
NAME := elfutils
SPECFILE = $(firstword $(wildcard *.spec))

TARGETS += elfutils-portability.patch

include ../common/Makefile.common

master-cvsroot = :gserver:cvs.devel.redhat.com:/cvs/devel

elfutils-portability.patch: elfutils-$(VERSION).tar.gz
	@rm -rf elfutils-master elfutils-portable
	cvs -d $(master-cvsroot) -Q export \
	    -d elfutils-master elfutils
	cvs -d $(master-cvsroot) -Q export \
	    -d elfutils-portable -r portable-branch elfutils
	cd elfutils-master; autoreconf
	cd elfutils-portable; autoreconf
	diff -rpu elfutils-master elfutils-portable | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@
