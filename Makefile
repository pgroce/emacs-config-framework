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


EMACS_HOME=$(shell $(EMACS) --batch --eval "(princ (directory-file-name user-emacs-directory))")

all: tangle README.md

tangle:
	rm -rf build && \
	mkdir -p build && \
	$(EMACS) --batch \
	  --visit=emacs-config-framework.org \
	  --eval "(org-babel-tangle nil)"
	touch build/config/scratch.el

README.md: emacs-config-framework.org
	$(PANDOC) -i emacs-config-framework.org \
	          -o build/README.md \
	          -w gfm


# Rules of installing:
# - We own emacs.d/config_default
# - We own emacs.d/config if it doesn't exist, and can update it if it does
# - We may not own init.el, so back it up

install-base: tangle
	mkdir -p $(EMACS_HOME)
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default

install: tangle
	@echo ""
	@echo "-----------------------------------------------------------"
	@echo "'make install' will:"
	@echo "- Create  $(EMACS_HOME)/init.el if it does not exist"
	@echo "- Create  $(EMACS_HOME)/early-init.el if it does not exist"
	@echo "- Create  $(EMACS_HOME)/config if it does not exist"
	@echo "- REPLACE $(EMACS_HOME)/config_default"
	@echo "-----------------------------------------------------------"
	@echo ""
	install -b build/init.el $(EMACS_HOME)/
	install -b build/early-init.el $(EMACS_HOME)/
	if [ ! -e $(EMACS_HOME)/config ]; then \
	    cp -rf build/config $(EMACS_HOME); \
	fi
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default

update: tangle
	@echo ""
	@echo "-----------------------------------------------------------"
	@echo "'make update' will:"
	@echo "REPLACE $(EMACS_HOME)/init.el"
	@echo "REPLACE $(EMACS_HOME)/early-init.el"
	@echo "REPLACE $(EMACS_HOME)/config/init.el"
	@echo "REPLACE $(EMACS_HOME)/config/early-init.el"
	@echo "Replace $(EMACS_HOME)/config_default"
	@echo "Leave   $(EMACS_HOME)/config/scratch.el alone"
	@echo "-----------------------------------------------------------"
	@echo ""
	cp build/init.el $(EMACS_HOME)/
	cp build/early-init.el $(EMACS_HOME)/
	mkdir -p $(EMACS_HOME)/config
	cp -f build/config/init.el $(EMACS_HOME)/config/
	cp -f build/config/early-init.el $(EMACS_HOME)/config/
	if [ ! -e $(EMACS_HOME)/config/scratch.el ]; then \
		cp -f build/config/scratch.el $(EMACS_HOME)/config/; \
	fi
	rm -rf $(EMACS_HOME)/config_default
	cp -rf build/config $(EMACS_HOME)/config_default
