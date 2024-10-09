;;; r-ts-mode.el --- Tree-sitter support for R buffers -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/r-ts-mode
;; Package-Requires: ((emacs "29.1") (ess "24"))
;; Created: 23 March 2024
;; Version: 0.1.0
;; Keywords: languages, R, tree-sitter

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Major mode for R using tree-sitter.
;;
;; This mode requires the tree-sitter parser from
;; https://github.com/r-lib/tree-sitter-r.
;;
;;; Code:

(require 'treesit)
(require 'ess-r-mode nil t) ; `ess-r-customize-alist', `ess-r-prettify-symbols'

(defvar ess-r-prettify-symbols)
(defvar ess-r-customize-alist)
(declare-function ess-setq-vars-local "")


(defcustom r-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `r-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'R)

(defcustom r-ts-mode-align-arguments t
  "When non-nil, align function arguments with the first argument.

For example, when non-nil, align arguments like:

    labs(title = \"....\",
         x = \"Date\")
    labs(
      title = \"....\",
      x = \"Date\")

Otherwise, when nil, arguments are indented with `r-ts-mode-indent-offset'."
  :type 'boolean
  :safe 'booleanp
  :group 'R)


;;; Indentation

(defun r-ts-mode--anchor-args (&rest args)
  "Calculate indentation anchor for function arguments.
See `treesit-simple-indent-rules' for details of ARGS."
  (apply (if r-ts-mode-align-arguments
             (funcall (alist-get 'nth-sibling treesit-simple-indent-presets) 1)
           (alist-get 'standalone-parent treesit-simple-indent-presets))
         args))

(defun r-ts-mode--indent-args (&rest _)
  "Calculate indent offest for arguments."
  (if r-ts-mode-align-arguments 0 r-ts-mode-indent-offset))

(defvar r-ts-mode--indent-rules
  `((r
     ((parent-is "program") column-0 0)
     ((node-is "}") standalone-parent 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is "else") parent-bol 0)
     ((node-is "braced_expression") standalone-parent 0)
     ((parent-is ,(rx bol (or "braced_expression" "parenthesized_expression")))
      standalone-parent r-ts-mode-indent-offset)
     ((parent-is ,(rx bow (or "if" "while" "repeat" "for") eow))
      parent-bol r-ts-mode-indent-offset)
     ;; ((n-p-gp nil "binary_operator" "if_statement") parent 0)
     ;; ((match "binary_operator" "if_statement") parent 0)
     ((parent-is "binary_operator") parent-bol r-ts-mode-indent-offset)
     ((parent-is "function_definition") parent-bol r-ts-mode-indent-offset)
     ((parent-is "parameters") parent-bol r-ts-mode-indent-offset)
     ;; Arguments
     ((node-is "arguments") parent-bol r-ts-mode-indent-offset)
     ((match "argument" nil nil 1 1) standalone-parent r-ts-mode-indent-offset)
     ((parent-is "arguments") r-ts-mode--anchor-args r-ts-mode--indent-args)

     ((parent-is "string") no-indent)
     (no-node parent-bol 0)))
  "Tree-sitter indent rules for R.")


;;; Font-locking

;; Keywords that are anonymous nodes in grammar
(defconst r-ts-mode--keywords
  '("if" "else" "repeat" "while" "for" "in" "function"))

;; Keywords to highlight in call expressions
(defconst r-ts-mode--keyword-calls
  '("on.exit" "stop" "stopifnot" ".Defunct" "tryCatch"
    "withRestarts" "invokeRestart"
    "recover" "browser"))

;; `ess-R-modifiers'
(defconst r-ts-mode--modifiers
  '("library" "attach" "detach" "source" "require"
    "setwd" "options" "par" "load" "rm"
    "message" "warning" ".Deprecated"
    "signalCondition" "withCallingHandlers"))

(defconst r-ts-mode--operators
  '("?" ":=" "=" "<-" "<<-" "->" "->>"
    "!" "~" "|>" "||" "|" "&&"  "&"
    "<" "<=" ">" ">=" "==" "!="
    "+" "-" "*" "/" "::" ":::"
    "**" "^" "$" "@" ":"
    ;; "\\"
    "special")
  "R operators for tree-sitter font-locking.")

(defconst r-ts-mode--brackets
  '("(" ")" "[" "]" "[[" "]]" "{" "}")
  "R brackets for tree-sitter font-locking.")

(defvar r-ts-mode-feature-list
  '(( comment definition)
    ( keyword string escape-sequence)
    ( builtin type constant number assignment function property)
    ( operator variable bracket delimiter))
  "`treesit-font-lock-feature-list' for `r-ts-mode'.")

(defvar r-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'r
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'r
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'r
   :feature 'escape-sequence
   :override t
   '((escape_sequence) @font-lock-escape-face)

   :language 'r
   :feature 'keyword
   `([,@r-ts-mode--keywords (dots) (break) (next) (return)] @font-lock-keyword-face

     (call
      function: ((identifier) @font-lock-keyword-face
                 (:match ,(rx-to-string
                           `(seq bos (or ,@r-ts-mode--keyword-calls) eos))
                         @font-lock-keyword-face)))

     (call
      function: ((identifier) @font-lock-preprocessor-face
                 (:match ,(rx-to-string
                           `(seq bos (or ,@r-ts-mode--modifiers) eos))
                         @font-lock-preprocessor-face)))
     ;; Lambda operator
     (function_definition
      name: "\\" @font-lock-keyword-face))

   :language 'r
   :feature 'operator
   `([,@r-ts-mode--operators] @font-lock-operator-face)

   :language 'r
   :feature 'definition
   '((parameter
      name: (identifier) @font-lock-variable-name-face)
     (argument
      name: (identifier) @font-lock-property-use-face)

     (binary_operator
      lhs: (identifier) @font-lock-function-name-face
      operator: "<-"
      rhs: (function_definition))

     (binary_operator
      lhs: (identifier) @font-lock-variable-name-face
      operator: "<-"
      rhs: (_))

     (for_statement
      variable: (identifier) @font-lock-variable-name-face))

   :language 'r
   :feature 'builtin
   '(("$" ((identifier) @font-lock-builtin-face
           (:match "self" @font-lock-builtin-face))))

   :language 'r
   :feature 'type
   '((namespace_operator
      lhs: (identifier) @font-lock-type-face))

   :language 'r
   :feature 'constant
   '([(true) (false) (null) (nan) (na) (inf)
      "NA_integer_" "NA_real_" "NA_complex_" "NA_character_"]
     @font-lock-constant-face)

   :language 'r
   :feature 'function
   '((call function: (identifier) @font-lock-function-call-face)

     (call function: (namespace_operator
                      rhs: (identifier) @font-lock-function-call-face))

     (call function: (extract_operator
                      rhs: (identifier) @font-lock-function-call-face)))

   :language 'r
   :feature 'property
   '((extract_operator
      rhs: (identifier) @font-lock-property-use-face))

   ;; :language 'r
   ;; :feature 'assignment
   ;; '()

   :language 'r
   :feature 'variable
   '((identifier) @font-lock-variable-use-face)

   :language 'r
   :feature 'number
   '([(integer) (float) (complex)] @font-lock-number-face)

   :language 'r
   :feature 'delimiter
   '([(comma)] @font-lock-delimiter-face)

   :language 'r
   :feature 'bracket
   `([,@r-ts-mode--brackets] @font-lock-bracket-face))
  "Tree-sitter font-lock settings for R.")


;;; Imenu

(defun r-ts-mode--defun-name (node)
  "Find name of NODE."
  (treesit-node-text
   (treesit-node-child-by-field-name
    (treesit-node-parent node) "lhs")))

(defun r-ts-mode--imenu-p (node)
  "Return non-nil if NODE should be included in imenu."
  (equal "binary_operator" (treesit-node-type (treesit-node-parent node))))


;;; Syntax
(defvar r-ts-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; From `S-syntax-table' (notes included)
    (modify-syntax-entry ?\\ "\\" table)
    (modify-syntax-entry ?+  "."  table)
    (modify-syntax-entry ?-  "."  table)
    (modify-syntax-entry ?=  "."  table)
    (modify-syntax-entry ?%  "."  table)
    (modify-syntax-entry ?<  "."  table)
    (modify-syntax-entry ?>  "."  table)
    (modify-syntax-entry ?&  "."  table)
    (modify-syntax-entry ?|  "."  table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?#  "<"  table)  ; open comment
    (modify-syntax-entry ?\n ">"  table)  ; close comment
    (modify-syntax-entry ?.  "_"  table)  ; see above/below,
                                        ; plus consider separation.
    (modify-syntax-entry ?$  "_"  table)  ; foo$comp = 1 symbol(completion)
    (modify-syntax-entry ?@  "_"  table)  ; foo@slot = 1 symbol(completion)
    (modify-syntax-entry ?_  "_"  table)
    (modify-syntax-entry ?:  "_"  table)
    (modify-syntax-entry ?*  "."  table)
    (modify-syntax-entry ?<  "."  table)
    (modify-syntax-entry ?>  "."  table)
    (modify-syntax-entry ?/  "."  table)
    ;; Rest from `ess-r-mode-syntax-table' (notes included)
    ;; Letting Emacs treat backquoted names and %ops% as strings solves
    ;; many problems with regard to nested strings and quotes
    (modify-syntax-entry ?` "\"" table)
    (modify-syntax-entry ?% "\"" table)
    ;; Underscore is valid in R symbols
    (modify-syntax-entry ?_ "_" table)
    ;; (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?@ "." table)
    (modify-syntax-entry ?$ "." table)
    (modify-syntax-entry ?\\ "." table)
    table)
  "Syntax table for `r-ts-mode'.")

;;;###autoload
(define-derived-mode r-ts-mode prog-mode "R"
  "Major mode for editing R, powered by tree-sitter."
  :group 'R
  :syntax-table r-ts-mode-syntax-table

  (when (treesit-ready-p 'r)
    (treesit-parser-create 'r)

    ;; Comments
    (setq-local comment-start "# ")
    (setq-local comment-end "")
    (setq-local comment-start-skip (rx "#" (* (syntax whitespace))))

    (setq-local paragraph-start (concat "\\s-*$\\|" page-delimiter))
    (setq-local paragraph-separate (concat "\\s-*$\\|" page-delimiter))
    (setq-local paragraph-ignore-fill-prefix t)
    (setq-local add-log-current-defun-header-regexp
                "^\\(.+\\)\\s-+<-[ \t\n]*function")

    (when (require 'ess-r-mode nil t)
      (setq-local prettify-symbols-alist ess-r-prettify-symbols)
      ;; For inferior ess
      (ess-setq-vars-local ess-r-customize-alist))

    ;; Indentation
    (setq-local electric-indent-chars
                (append "{}()," (if (boundp 'electric-indent-chars)
                                    electric-indent-chars
                                  '(?\n))))
    (setq-local electric-layout-rules
                `((?\{ . after) (?\} . before)
                  (?\, . after) (?\) . before)))
    (setq-local treesit-simple-indent-rules r-ts-mode--indent-rules
                indent-tabs-mode nil)

    ;; Font-Locking
    (setq-local treesit-font-lock-settings r-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list r-ts-mode-feature-list)

    ;; Imenu
    (setq-local treesit-simple-imenu-settings
                '(("Function" "\\`function_definition\\'" r-ts-mode--imenu-p)))

    (setq-local treesit-defun-name-function #'r-ts-mode--defun-name)
    (setq-local treesit-defun-type-regexp
                (rx (or "lambda_function" "function_definition")))

    ;; TODO: Navigation
    (setq-local treesit-thing-settings nil)

    (treesit-major-mode-setup)))


(when (fboundp 'derived-mode-add-parents)
  (derived-mode-add-parents 'r-ts-mode '(ess-r-mode)))

(if (treesit-ready-p 'r)
    (add-to-list 'auto-mode-alist '("\\.R\\'" . r-ts-mode)))

(provide 'r-ts-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; r-ts-mode.el ends here
