SHELL  = /bin/bash

TSDIR   ?= $(CURDIR)/tree-sitter-r
TESTDIR ?= $(CURDIR)/test
BINDIR  ?= $(CURDIR)/bin

all:
	@

dev: $(TSDIR)
$(TSDIR):
	@git clone https://github.com/r-lib/tree-sitter-r
	@printf "\33[1m\33[31mNote\33[22m npm build can take a while" >&2
	@cd $(TSDIR) && git checkout next &&                   \
		npm --loglevel=info --progress=true install && \
		npm run build

.PHONY: parse-% extract-tests
extract-tests: dev
	@cd $(TSDIR)/test/corpus && find . -type f -name "*.txt" -print0 | \
		while IFS= read -r -d '' f; do                             \
		ff="$$(basename $$f)";                                     \
		$(BINDIR)/examples.rb < $$f > $(TESTDIR)/$${ff%.*}.R;      \
	done

parse-%: dev
	@cd $(TSDIR) && npx tree-sitter parse $(TESTDIR)/$(subst parse-,,$@)

clean:
	$(RM) -r *~

distclean: clean
	$(RM) -rf $$(git ls-files --others --ignored --exclude-standard)
