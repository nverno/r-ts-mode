# R major mode using tree-sitter

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This package is compatible with and was tested against the tree-sitter grammar
for R found at [tree-sitter-r](https://github.com/r-lib/tree-sitter-r/tree/next).

The master branch uses the latest grammar from the tree-sitter-r [next
branch](https://github.com/r-lib/tree-sitter-r/tree/next).
The 'main' branch uses the old grammar from the tree-sitter-r [main
branch](https://github.com/r-lib/tree-sitter-r/tree/main).


This mode provides:
+ indentation
+ font-locking

**TODO**:
+ imenu
+ navigation
 

![example](doc/r-ts-mode.png)

## Installing

Emacs 29.1 or above with tree-sitter support is required. 

Tree-sitter starter guide: https://git.savannah.gnu.org/cgit/emacs.git/tree/admin/notes/tree-sitter/starter-guide?h=emacs-29

### Install tree-sitter parser for R

Add the source to `treesit-language-source-alist`. 

```elisp
;; Use the 'next' branch for latest grammar
(add-to-list
 'treesit-language-source-alist
 '(r "https://github.com/r-lib/tree-sitter-r" "next"))
;; Older grammar used by 'main' branch
;; (add-to-list
;; 'treesit-language-source-alist
;; '(r "https://github.com/r-lib/tree-sitter-r"))
```

Then run `M-x treesit-install-language-grammar` and select `r` to install.

### Install r-ts-mode.el from source

- Clone this repository
- Add the following to your emacs config

```elisp
(require "[cloned nverno/r-ts-mode]/r-ts-mode.el")
```

### Troubleshooting

If you get the following warning:

```
⛔ Warning (treesit): Cannot activate tree-sitter, because tree-sitter
library is not compiled with Emacs [2 times]
```

Then you do not have tree-sitter support for your emacs installation.

If you get the following warnings:
```
⛔ Warning (treesit): Cannot activate tree-sitter, because language grammar for r is unavailable (not-found): (libtree-sitter-r libtree-sitter-r.so) No such file or directory
```

then the R grammar files are not properly installed on your system.
