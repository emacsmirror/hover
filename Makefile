SHELL=/usr/bin/env bash

EMACS ?= emacs
CASK ?= cask

INIT="(progn \
  (require 'package) \
  (push '(\"melpa\" . \"https://melpa.org/packages/\") package-archives) \
  (package-initialize) \
  (package-refresh-contents))"

LINT="(progn \
		(unless (package-installed-p 'package-lint) \
		  (package-install 'package-lint)) \
		(require 'package-lint) \
		(setq package-lint-main-file \"hover.el\") \
		(package-lint-batch-and-exit))"

build:
	cask install

ci: clean build compile checkdoc lint

compile:
	@echo "Compiling..."
	@$(CASK) $(EMACS) -Q --batch \
		-L . \
		--eval '(setq byte-compile-error-on-warn t)' \
		-f batch-byte-compile \
		*.el

checkdoc:
	$(eval LOG := $(shell mktemp -d)/checklog.log)
	@touch $(LOG)

	@echo "checking doc..."

	@for f in *.el ; do \
		$(CASK) $(EMACS) -Q --batch \
			-L . \
			--eval "(checkdoc-file \"$$f\")" \
			*.el 2>&1 | tee -a $(LOG); \
	done

	@if [ -s $(LOG) ]; then \
		echo ''; \
		exit 1; \
	else \
		echo 'checkdoc ok!'; \
	fi

lint:
	@echo "package linting..."
	@$(CASK) $(EMACS) -Q --batch \
		-L . \
		--eval $(INIT) \
		--eval $(LINT) \
		*.el

clean:
	rm -rf .cask *.elc

tag:
	$(eval TAG := $(filter-out $@,$(MAKECMDGOALS)))
	sed -i "s/;; Version: [0-9]\+.[0-9]\+.[0-9]\+/;; Version: $(TAG)/g" hover.el
	git add hover.el
	git commit -m "Bump hover: $(TAG)"
	git tag $(TAG)
	git push origin HEAD
	git push origin --tags

# Allow args to make commands
%:
	@:

.PHONY: build ci compile checkdoc lint clean tag
