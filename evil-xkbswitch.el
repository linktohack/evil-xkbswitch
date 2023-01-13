;;; evil-xkbswitch.el --- Input method switching corresponds to current state.

(require 'evil)

(defvar evil-xkbswitch-set-layout (if (eq system-type 'darwin) "issw" "xkb-switch -s")
  "Set xkb layout.")
(defvar evil-xkbswitch-get-layout (if (eq system-type 'darwin) "issw" "xkb-switch")
  "Get xkb layout.")
(defvar evil-xkbswitch--us-method (if (eq system-type 'darwin) "com.apple.keylayout.US" "us")
  "US input method.")
(defvar evil-xkbswitch--last-method nil
  "Last input method.")
(defvar evil-xkbswitch--in-minibuffer nil
  "Whether currently in minibuffer, which requires switching layout.")
(defvar evil-xkbswitch-verbose nil
  "Verbose?")

(defun evil-xkbswitch-to-us ()
  "Switch input method to US.
Save last method into `evil-xkbswitch--last-method'."
  (interactive)
  (setq evil-xkbswitch--last-method
        (replace-regexp-in-string "\n" ""
          (shell-command-to-string
            (format "%s" evil-xkbswitch-get-layout))))
  (shell-command-to-string (format "%s '%s'"
                                   evil-xkbswitch-set-layout
                                   evil-xkbswitch--us-method))
  (when evil-xkbswitch-verbose
    (message "Current method (us) %s" evil-xkbswitch--us-method)))

(defun evil-xkbswitch-to-alternate ()
  "Restore last input method."
  (interactive)
  (when evil-xkbswitch--last-method
    (shell-command-to-string (format "%s '%s'"
                                     evil-xkbswitch-set-layout
                                     evil-xkbswitch--last-method)))
  (when evil-xkbswitch-verbose
    (message "Current method (alternate) %s" evil-xkbswitch--last-method)))

(defun evil-xkbswitch--wrapper-function (original-fun &rest args)
  "Use alternate layout while ORIGINAL-FUN called with ARGS is running."
  (evil-xkbswitch-to-alternate)
  (unwind-protect
      (apply original-fun args)
    (evil-xkbswitch-to-us)))

(defun evil-xkbswitch--wrap-function (fun)
  "Advice to use alternate layout while FUN is running."
  (advice-add fun :around #'evil-xkbswitch--wrapper-function))

(defun evil-xkbswitch--unwrap-function (fun)
  "Revert advice to use alternate layout while FUN is running."
  (advice-remove fun #'evil-xkbswitch--wrapper-function))

(defun evil-xkbswitch-switch-layout-in-minibuffer-p ()
  "Whether evil-xkbswitch should switch layout in current minibuffer."
  (evil-xkbswitch--ex-search-minibuffer-p))

(defun evil-xkbswitch--ex-search-minibuffer-p ()
  "Whether minibuffer is ex search minibuffer (triggered by / or ?)."
  (and (evil-ex-p)
       (let ((prompt (minibuffer-prompt)))
         (or (string= prompt "/") (string= prompt "?")))))

;; BUG: After exiting minibuffer, layout is switched to US,
;; even if layout was alternate before exiting minibuffer
;; (user could have opened minibuffer in insert mode).
;;
;; BUG: evil-xkbswitch doesn't work well with evil-want-minibuffer,
;; because of a bug in evil: it always triggers insert-state-entry-hook
;; after exiting minibuffer, so user ends up with an alternate layout in normal mode.
;;
;; BUG: Also, with evil-want-minibuffer layout is switched for every minibuffer,
;; which is probably undesirable.

(defun evil-xkbswitch--minibuffer-to-alternate ()
  "Handle switching input method after entering minibuffer."
  (when (and (not evil-want-minibuffer) (evil-xkbswitch-switch-layout-in-minibuffer-p))
    (setq evil-xkbswitch--in-minibuffer t)
    (evil-xkbswitch-to-alternate)))

(defun evil-xkbswitch--minibuffer-to-us ()
  "Handle switching input method to US after exiting minibuffer."
  (when (and (not evil-want-minibuffer) evil-xkbswitch--in-minibuffer)
    (evil-xkbswitch-to-us)
    (setq evil-xkbswitch--in-minibuffer nil)))

;;;###autoload
(define-minor-mode evil-xkbswitch-mode
  "Switch input."
  :global t
  :lighter " xkb"
  (if evil-xkbswitch-mode
      (progn
        (add-hook 'evil-insert-state-entry-hook #'evil-xkbswitch-to-alternate)
        (add-hook 'evil-insert-state-exit-hook #'evil-xkbswitch-to-us)
        (add-hook 'evil-replace-state-entry-hook #'evil-xkbswitch-to-alternate)
        (add-hook 'evil-replace-state-exit-hook #'evil-xkbswitch-to-us)
        (evil-xkbswitch--wrap-function #'evil-read-key)
        (add-hook 'minibuffer-setup-hook #'evil-xkbswitch--minibuffer-to-alternate)
        (add-hook 'minibuffer-exit-hook #'evil-xkbswitch--minibuffer-to-us))
    (remove-hook 'evil-insert-state-entry-hook #'evil-xkbswitch-to-alternate)
    (remove-hook 'evil-insert-state-exit-hook #'evil-xkbswitch-to-us)
    (remove-hook 'evil-replace-state-entry-hook #'evil-xkbswitch-to-alternate)
    (remove-hook 'evil-replace-state-exit-hook #'evil-xkbswitch-to-us)
    (evil-xkbswitch--unwrap-function #'evil-read-key)
    (remove-hook 'minibuffer-setup-hook #'evil-xkbswitch--minibuffer-to-alternate)
    (remove-hook 'minibuffer-exit-hook #'evil-xkbswitch--minibuffer-to-us)))

(define-global-minor-mode global-evil-xkbswitch-mode evil-xkbswitch-mode evil-xkbswitch-mode)

(provide 'evil-xkbswitch)
