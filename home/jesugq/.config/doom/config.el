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

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

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


(setq x-control-keysym 'control
      x-meta-keysym 'meta
      x-super-keysym 'super)
(map! :g "<C-prior>" #'previous-buffer
      :g "<C-next>"  #'next-buffer)

; (setq mac-command-modifier 'control
;       mac-option-modifier  'super
;       mac-control-modifier 'meta)
; (map! :g "C-{" #'previous-buffer
;       :g "C-}" #'next-buffer)

(add-hook 'text-mode-hook #'visual-fill-column-mode)
(setq-default visual-fill-column-center-text t)
(setq doom-font (font-spec :family "Office Code Pro" :size 22))

(after! org
  (setq org-directory "~/Sync/Apps/Orgmode")
;   (setq org-directory "~/Development/orgmode")
  (setq org-default-notes-file (expand-file-name "@inbox.org" org-directory))
  (setq org-agenda-files
      (mapcar (lambda (path) (expand-file-name path org-directory))
              '("."
                "insights"
                "notepads"
                "outlines"
                "projects"
                "routines")
      )
  )
  (setq org-log-done 'time)
  (setq org-startup-folded t)
  (setq org-priority-highest ?A
        org-priority-lowest  ?D
        org-priority-default ?D)
  (setq org-priority-faces
        `((?A :foreground ,(doom-color 'red) :weight bold)
          (?B :foreground ,(doom-color 'orange) :weight bold)
          (?C :foreground ,(doom-color 'blue) :weight bold)
          (?D :foreground ,(doom-color 'dark-cyan) :weight bold)
         )
  )
  (setq org-todo-keywords '((sequence "LOOP(l)" "TODO(t)" "HOLD(h)" "NEXT(n)" "|" "DONE(d)" "KILL(k)")))
  (setq org-todo-keyword-faces
        `(("LOOP" :foreground ,(doom-color 'dark-cyan) :weight bold)
          ("TODO" :foreground ,(doom-color 'blue) :weight bold)
          ("HOLD" :foreground ,(doom-color 'orange) :weight bold)
          ("NEXT" :foreground ,(doom-color 'red) :weight bold)))
  (setq org-agenda-custom-commands
      '(("o" "Orgzly"
         ((todo "NEXT")
          (todo "HOLD")
          (tags-todo "+PRIORITY=\"A\"/-NEXT-HOLD")
          (tags-todo "+PRIORITY=\"B\"/-NEXT-HOLD")
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
  (setq org-capture-templates
        '(("g" "Goals" entry (file "@goals.org") "* %?")
          ("i" "Inbox" entry (file "@inbox.org") "* %?")
          ("l" "Lists" entry (file "@lists.org") "* %?")
          ("n" "Notes" entry (file "@notes.org") "* %?")
          ("t" "Tasks" entry (file "@tasks.org") "* %?")))
)
