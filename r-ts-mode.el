;;; r-ts-mode.el --- Tree-sitter support for R buffers -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/r-ts-mode
;; Package-Requires: ((emacs "29.1") (ess "24"))
;; Created: 23 March 2024
;; Version: 0.0.1
;; Keywords: languages R tree-sitter

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
;;; Code:

(require 'treesit)
(require 'ess-r-mode)                   ; syntax


(defcustom r-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `r-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'R)


;;; Indentation

(defvar r-ts-mode--indent-rules
  `((r
     ((parent-is "program") column-0 0)
     ((node-is "}") standalone-parent 0)
     ((node-is ")") parent-bol 0)
     ((node-is "]") parent-bol 0)
     ((node-is "else") parent-bol 0)
     ;; closing '}' => standalone-parent to match left_assignment opener
     ((node-is "brace_list") standalone-parent 0)
     ((parent-is ,(rx bow (or "brace_list" "paren_list") eow))
      standalone-parent r-ts-mode-indent-offset)
     ((parent-is ,(rx bow (or "special" "pipe") eow))
      parent-bol r-ts-mode-indent-offset)
     ((parent-is ,(rx bow (or "if" "while" "repeat" "for") eow))
      parent-bol r-ts-mode-indent-offset)
     ((parent-is "binary") parent-bol r-ts-mode-indent-offset)
     ((parent-is "function_definition") parent-bol r-ts-mode-indent-offset)
     ((parent-is "call") parent-bol r-ts-mode-indent-offset)
     ((parent-is "left_assignment") parent-bol r-ts-mode-indent-offset)
     ((node-is "arguments") parent-bol r-ts-mode-indent-offset)
     ((parent-is "arguments") first-sibling 0)
     ((parent-is "formal_parameters") first-sibling 1)
     ((parent-is "string") no-indent)
     (no-node parent-bol 0)))
  "Tree-sitter indent rules for `r-ts-mode'.")


;;; Font-locking

;; Keywords that are anonymous nodes in grammar
(defconst r-ts-mode--keywords
  '("if" "else" "repeat" "while" "for" "in" "switch" "function"))

;; Keywords to highlight in call expressions
(defconst r-ts-mode--keyword-calls
  '("return" "on.exit" "stop" ".Defunct" "tryCatch"
    "withRestarts" "invokeRestart"
    "recover" "browser"))

;; `ess-R-modifiers'
(defconst r-ts-mode--modifiers
  '("library" "attach" "detach" "source" "require"
    "setwd" "options" "par" "load" "rm"
    "message" "warning" ".Deprecated"
    "signalCondition" "withCallingHandlers"))

(defconst r-ts-mode--operators
  '(":=" "=" "<-" "<<-" "->" "->>"
    "|>" "|"
    "!" "&&" "||" "&"
    "<" "<=" ">" ">=" "==" "!="
    "+" "-" "*" "/" "?" "~" "^"
    "$" "@" "\\" "::" ":::" ":")
  "R operators for tree-sitter font-locking.")

(defconst r-ts-mode--delimiters
  '("," ";")
  "R delimiters for tree-sitter font-locking.")

(defconst r-ts-mode--brackets
  '("(" ")" "[" "]" "[[" "]]" "{" "}"))

(defvar r-ts-mode-feature-list
  '(( comment definition)
    ( keyword string escape-sequence)
    ( builtin type constant number assignment function) ; property
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
   `([,@r-ts-mode--keywords (dots) (break) (next)] @font-lock-keyword-face

     (call
      function: ((identifier) @font-lock-keyword-face
                 (:match ,(rx-to-string
                           `(seq bos (or ,@r-ts-mode--keyword-calls) eos))
                         @font-lock-keyword-face)))

     (call
      function: ((identifier) @font-lock-preprocessor-face
                 (:match ,(rx-to-string
                           `(seq bos (or ,@r-ts-mode--modifiers) eos))
                         @font-lock-preprocessor-face))))

   :language 'r
   :feature 'definition
   '((formal_parameters (identifier) @font-lock-variable-name-face)

     (formal_parameters
      (default_parameter
       name: (identifier) @font-lock-variable-name-face))

     (default_argument
      name: (identifier) @font-lock-variable-name-face)

     (left_assignment
      name: (identifier) @font-lock-function-name-face _
      value: (function_definition))

     (left_assignment
      name: (identifier) @font-lock-variable-name-face _
      value: (_))

     (for
      name: (identifier) @font-lock-variable-name-face))

   :language 'r
   :feature 'builtin
   '((dollar ((identifier) @font-lock-builtin-face
              (:match "self" @font-lock-builtin-face))))

   :language 'r
   :feature 'type
   '((namespace_get
      namespace: (identifier) @font-lock-type-face)
     (namespace_get_internal
      namespace: (identifier) @font-lock-type-face))

   :language 'r
   :feature 'constant
   '([(true) (false) (null) (nan) (na) (inf)
      "NA_integer_" "NA_real_" "NA_complex_" "NA_character_"]
     @font-lock-constant-face)

   :language 'r
   :feature 'function
   '((call function: (identifier) @font-lock-function-call-face)

     (call function: (namespace_get
                      function: (identifier) @font-lock-function-call-face))

     (call function: (namespace_get_internal
                      function: (identifier) @font-lock-function-call-face))

     (call function: (dollar _ (identifier) @font-lock-function-call-face)))

   ;; :language 'r
   ;; :feature 'assignment
   ;; '()

   :language 'r
   :feature 'variable
   '((dollar (identifier) @font-lock-variable-use-face
             "$" (identifier) @font-lock-property-use-face)

     (identifier) @font-lock-variable-use-face)

   :language 'r
   :feature 'number
   '([(integer) (float) (complex)] @font-lock-number-face)

   :language 'r
   :feature 'operator
   `([,@r-ts-mode--operators (special)] @font-lock-operator-face)

   :language 'r
   :feature 'delimiter
   `([,@r-ts-mode--delimiters] @font-lock-delimiter-face)

   :language 'r
   :feature 'bracket
   `([,@r-ts-mode--brackets] @font-lock-bracket-face))
  "Tree-sitter font-lock settings for R.")

;;; Mode

;;;###autoload
(define-derived-mode r-ts-mode prog-mode "R"
  "Major mode for editing R, powered by tree-sitter."
  :group 'R
  :syntax-table ess-r-mode-syntax-table

  (when (treesit-ready-p 'r)
    (treesit-parser-create 'r)

    ;; Comments
    (setq-local comment-start "# ")
    (setq-local comment-end "")
    (setq-local comment-start-skip (rx "#" (* (syntax whitespace))))
    (setq-local paragraph-start (concat "\\s-*$\\|" page-delimiter))
    (setq-local paragraph-separate (concat "\\s-*$\\|" page-delimiter))
    (setq-local paragraph-ignore-fill-prefix t)

    ;; Indentation
    (setq-local treesit-simple-indent-rules r-ts-mode--indent-rules
                indent-tabs-mode nil)

    ;; Font-Locking
    (setq-local treesit-font-lock-settings r-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list r-ts-mode-feature-list)

    ;; TODO: Navigation
    (setq-local treesit-defun-type-regexp
                (rx (or "lambda_function" "function_definition")))
    ;; (setq-local treesit-defun-name-function #'r-ts-mode--defun-name)

    ;; TODO: Imenu
    (setq-local treesit-simple-imenu-settings
                '(("Function" "\\`function_definition'")))

    (treesit-major-mode-setup)))

(provide 'r-ts-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; r-ts-mode.el ends here
