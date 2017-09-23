# If (the right) Emacs isn't in your path, define the variable EMACS
# in localvars.mk.  e.g.
# EMACS="/Applications/Emacs.app/Contents/MacOS/Emacs"
-include localvars.mk

ifndef EMACS
EMACS=`which emacs`
endif

ifndef PANDOC
PANDOC=`which pandoc`
endif

EMACS_HOME=$(shell $(EMACS) --batch --eval "(princ user-emacs-directory)")

all: tangle README.md

tangle:
	rm -rf build && \
	mkdir -p build && \
	$(EMACS) --batch \
	--visit=emacs-config-framework.org \
	--eval "(progn (require 'ob) (cd \"build\") (org-babel-tangle nil))"

README.md: emacs-config-framework.org
	$(PANDOC) -i emacs-config-framework.org \
	          -o README.md \
	          -w markdown_github

install: tangle
	@echo "This will annihilate your ~/.emacs.d/init.el! RUN THIS CAREFULLY"
	@echo "To install, run the following:"
	@echo cp build/*.el $(EMACS_HOME)
	@echo rm -rf $(EMACS_HOME)/config
	@echo cp -rf build/config $(EMACS_HOME)
