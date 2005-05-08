# Makefile for source rpm: elfutils
# $Id: Makefile,v 1.1 2004/09/09 04:28:54 cvsdist Exp $
NAME := elfutils
SPECFILE = $(firstword $(wildcard *.spec))

include ../common/Makefile.common

elfutils-portability.patch: elfutils-$(VERSION).tar.gz portable.patch
	rm -rf elfutils-$(VERSION) elfutils-$(VERSION).orig
	tar xzf $<
	mv elfutils-$(VERSION) elfutils-$(VERSION).orig
	tar xzf $<
	patch -p1 -d elfutils-$(VERSION) < portable.patch
	cd elfutils-$(VERSION); autoreconf
	diff -rpu elfutils-$(VERSION).orig elfutils-$(VERSION) | \
	filterdiff --remove-timestamps > $@.new
	mv $@.new $@
