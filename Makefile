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
	touch build/config/scratch.el

README.md: emacs-config-framework.org
	$(PANDOC) -i emacs-config-framework.org \
	          -o README.md \
	          -w markdown_github


# Rules of installing:
# - We own emacs.d/config_default
# - We own emacs.d/config if it doesn't exist, and can update it if it does
# - We may not own init.el, so back it up

install-base: tangle
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default

install: tangle
	@echo ""
	@echo "'make install' will:"
	@echo "- Non-destructively replace $(EMACS_HOME)/init.el"
	@echo "- Not change $(EMACS_HOME)/config if it exists"
	@echo "- Install/replace $(EMACS_HOME)/config_default"
	@echo ""
	install -b build/init.el $(EMACS_HOME)/
	if [ ! -e $(EMACS_HOME)/config ]; then \
	    cp -rf build/config $(EMACS_HOME); \
	fi
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default

update: tangle
	@echo ""
	@echo "'make update' will:"
	@echo "DESTRUCTIVELY replace $(EMACS_HOME)/init.el"
	@echo "REPLACE $(EMACS_HOME)/config if it exists"
	@echo "Install/replace $(EMACS_HOME)/config_default"
	@echo ""
	install build/init.el $(EMACS_HOME)/
	rm -rf $(EMACS_HOME)/config
	cp -rf build/config $(EMACS_HOME)
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default
