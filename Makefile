

# If (the right) Emacs isn't in your path, define the variable EMACS
# in localvars.mk.  e.g.
# EMACS="/Applications/Emacs.app/Contents/MacOS/Emacs"
-include localvars.mk

ifndef EMACS
EMACS=`which emacs`
endif

EMACS_HOME=$(shell $(EMACS) --batch --eval "(princ user-emacs-directory)")

all: tangle

tangle:
	rm -rf build && \
	mkdir -p build && \
	$(EMACS) --batch \
	--visit=emacs-config-framework.org \
	--eval "(progn (require 'ob) (cd \"build\") (org-babel-tangle nil))"

install: tangle
	cp build/*.el $(EMACS_HOME)
	rm -rf $(EMACS_HOME)/config
	cp -rf build/config $(EMACS_HOME)
