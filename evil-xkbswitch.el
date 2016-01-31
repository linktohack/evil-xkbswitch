;;; evil-xkbswitch.el --- Input method switching corresponds to current state.

(defvar evil-xkbswitch-binary "issw"
  "Switch input binary.")
(defvar evil-xkbswitch--us-method "com.apple.keylayout.US"
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
        (shell-command-to-string
         (format "%s" evil-xkbswitch-binary)))
  (shell-command-to-string (format "%s %s"
                                   evil-xkbswitch-binary
                                   evil-xkbswitch--us-method))
  (when evil-xkbswitch-verbose
    (message "Current method %s" evil-xkbswitch--us-method)))

(defun evil-xkbswitch-to-alternate ()
  "Restore last input method."
  (interactive)
  (when evil-xkbswitch--last-method
    (shell-command-to-string
     (format "%s %s"
             evil-xkbswitch-binary
             evil-xkbswitch--last-method)))
  (when evil-xkbswitch-verbose
    (message "Current method %s" evil-xkbswitch--last-method)))

;;;###autoload
(define-minor-mode evil-xkbswitch-mode
  "Switch input."
  :global t
  :lighter " xkb"
  (if evil-xkbswitch-mode
      (progn
        (add-hook 'evil-insert-state-entry-hook #'evil-xkbswitch-to-alternate)
        (add-hook 'evil-insert-state-exit-hook #'evil-xkbswitch-to-us))
    (remove-hook 'evil-insert-state-entry-hook #'evil-xkbswitch-to-alternate)
    (remove-hook 'evil-insert-state-exit-hook #'evil-xkbswitch-to-us)))

(provide 'evil-xkbswitch)
