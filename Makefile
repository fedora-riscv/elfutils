# Makefile for source rpm: elfutils
# $Id$
NAME := elfutils
SPECFILE = $(firstword $(wildcard *.spec))

include ../common/Makefile.common
