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
        (evil-xkbswitch--wrap-function #'evil-read-key))
    (remove-hook 'evil-insert-state-entry-hook #'evil-xkbswitch-to-alternate)
    (remove-hook 'evil-insert-state-exit-hook #'evil-xkbswitch-to-us)
    (remove-hook 'evil-replace-state-entry-hook #'evil-xkbswitch-to-alternate)
    (remove-hook 'evil-replace-state-exit-hook #'evil-xkbswitch-to-us)
    (evil-xkbswitch--unwrap-function #'evil-read-key)))

(define-global-minor-mode global-evil-xkbswitch-mode evil-xkbswitch-mode evil-xkbswitch-mode)

(provide 'evil-xkbswitch)
