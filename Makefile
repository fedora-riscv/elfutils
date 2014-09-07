patches := $(patsubst %,elfutils-%.patch,portability)

.PHONY: patches
patches: $(patches)

branch-portability = portable

FORCE:;

elfutils.git ?= ${HOME}/src/elfutils/.git
git-heads := $(wildcard $(elfutils.git)/refs/heads/*)
ifneq (,$(git-heads))
git-dir = git --git-dir=$(elfutils.git)
git-archive = $(git-dir) archive
get-master = master=`$(git-dir) merge-base master $$branch` && \
	     master=`$(git-dir) describe --tags --always $$master`
else
git-heads = FORCE
git-archive = git archive --remote=git://git.fedorahosted.org/git/elfutils.git
get-master = master=master
endif

git-%/configure: Makefile $(git-heads)
	@rm -rf $(@D)
	$(git-archive) --prefix=$(@D)/ $(firstword $(branch-$*) $*) | tar xf -
	cd $(@D) && autoreconf -i && rm -rf autom4te.cache

elfutils-%.patch: git-%/configure
	branch=$(firstword $(branch-$*) $*); \
	$(get-master) && \
	(set -x; $(MAKE) git-$$master/configure) && \
	(set -x; diff --exclude='.gitignore' -Nrpu git-$$master $(<D)) | \
	filterdiff --remove-timestamps --strip=1 --addprefix=elfutils/ > $@.new
	mv $@.new $@

elfutils-portable.spec: elfutils.spec
	(echo '%define _with_compat 1'; sed 's/ check$$/& || :/' $<) > $@.new
	mv -f $@.new $@

rpmbuild-dirs = $(foreach what,source spec srcrpm,--define '_$(what)dir .')

.PHONY: portable-srpm
portable-srpm: elfutils-portable.spec $(patches) sources
	rpmbuild-md5 $(rpmbuild-dirs) -bs $<
