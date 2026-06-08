;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
(setq doom-font (font-spec :family "Office Code Pro" :size 30))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'kaolin-modo-dark)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'visual)
(setq line-move-visual t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Sync/Apps/Orgmode")
; (setq org-directory "~/Development/orgmode")

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(map! :gn "<C-prior>" #'centaur-tabs-backward
      :gn "<C-next>"  #'centaur-tabs-forward)
; (setq mac-command-modifier 'meta)
; (map! :gn "M-{" #'centaur-tabs-backward
;       :gn "M-}" #'centaur-tabs-forward)

(add-hook 'text-mode-hook #'visual-fill-column-mode)
(setq-default visual-fill-column-center-text t)

(custom-set-faces!
  `(region :background ,gray0 :foreground unspecified))

(setq cerise0 "#e121b1"
      magenta0 "#c932c9"
      purple0 "#ab33eb"
      violet0 "#853ae1"

      cyan1 "#57bfc2"
      teal1 "#4d9391"
      aquamarine1 "#47ba99"
      spring-green1 "#35bf88"

      gray0 "#353b3c")

(after! org
  (setq org-default-notes-file (expand-file-name "@inbox.org" org-directory))
  (setq org-agenda-files
      (mapcar (lambda (path) (expand-file-name path org-directory))
              '("."
                "01 insights"
                "02 PROJECTS"
                "03 routines"
                "04 FEATURES"
                "05 outlines"
                "06 NOTEPADS")
      )
  )
  (setq org-log-done 'time)
  (setq org-startup-folded t)
  (setq org-priority-highest ?A
        org-priority-lowest  ?D
        org-priority-default ?D)
  (setq org-priority-faces
        `((?A :foreground ,cerise0 :weight bold)
          (?B :foreground ,magenta0 :weight bold)
          (?C :foreground ,purple0 :weight bold)
          (?D :foreground ,violet0 :weight bold)
         )
  )
  (setq org-todo-keywords '((sequence "TODO(t)" "FUZZY(f)" "READY(r)" "|" "DONE(d)")))
  (setq org-todo-keyword-faces
        `(("TODO" :foreground ,cyan1 :weight bold)
          ("FUZZY" :foreground ,teal1 :weight bold)
          ("READY" :foreground ,aquamarine1 :weight bold)
          ("DONE" :foreground ,spring-green1 :weight bold)
         )
  )
  (setq org-agenda-custom-commands
      '(("o" "Option"
         ((todo "READY")
          (todo "FUZZY")
         )
        )
        ("p" "Priority"
         ((tags-todo "+PRIORITY=\"A\"/TODO")
          (tags-todo "+PRIORITY=\"B\"/TODO")
         )
        )
        ("a" "Agenda"
         ((agenda ""
                  ((org-agenda-span 10)
                   (org-agenda-show-log nil)
                   (org-agenda-skip-function '(org-agenda-skip-entry-if 'done))
                  )
         ))
        )
        ("c" "Closed"
         ((agenda ""
                  ((org-agenda-span 31)
                   (org-agenda-start-day "-30d")
                   (org-agenda-show-all-dates nil)
                   (org-agenda-show-log 'closed)
                   (org-agenda-log-mode-items '(closed))
                   (org-agenda-entry-types '(:closed))
                  )
          ))
        )
      )
  )
  (setq org-agenda-dim-blocked-tasks nil)
  (setq org-tag-alist
        '(("inner" . ?i)
          ("outer" . ?o)
          ("coder" . ?c)
          ("phone" . ?p)
          ("einks" . ?e)))
  (setq org-tags-match-list-sublevels nil)
  (setq org-capture-templates
        '(("n" "Inbox" entry (file "@inbox.org") "* %?"))
  )
)
