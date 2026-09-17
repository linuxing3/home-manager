;;; Minimal robust EXWM initialization -*- lexical-binding: t; -*-
(let ((user-init (expand-file-name "init.el" user-emacs-directory)))
  (when (file-readable-p user-init)
    (load user-init nil t)))

(unless (bound-and-true-p exwm--connection)
  (require 'exwm)
  (require 'exwm-systemtray)

  ;; Workspaces
  (setq exwm-workspace-number 4)

  ;; Buffer naming
  (add-hook 'exwm-update-class-hook
            (lambda ()
              (unless (or (string-prefix-p "sun-awt-X11-" exwm-instance-name)
                          (string= "gimp" exwm-instance-name))
                (exwm-workspace-rename-buffer exwm-class-name))))

  (add-hook 'exwm-update-title-hook
            (lambda ()
              (when (and exwm-title (not (string-prefix-p "sun-awt-X11-" exwm-instance-name)))
                (exwm-workspace-rename-buffer (format "%s: %s" exwm-class-name exwm-title)))))

      ;; System tray
      (if (fboundp 'exwm-systemtray-enable)
          (exwm-systemtray-enable)
        (when (fboundp 'exwm-systemtray-mode)
          (exwm-systemtray-mode 1)))

      ;; Global keybindings
      (setq exwm-input-global-keys
            `(([?\s-\r] . (lambda () (interactive) (start-process-shell-command "st" nil "st")))
              ([?\s-d] . (lambda () (interactive) (start-process-shell-command "dmenu" nil "dmenu_run -l 10")))
              ([?\s-g] . (lambda () (interactive) (start-process-shell-command "brave" nil "brave")))
              ([?\s-e] . (lambda () (interactive) (start-process-shell-command "editor" nil "st -t hx -e hx")))
              ([?\s-N] . (lambda () (interactive) (start-process-shell-command "nnn" nil "st -e nnn")))
              ([?\s-q] . (lambda () (interactive) (if (derived-mode-p 'exwm-mode) (kill-buffer (current-buffer)) (kill-buffer))))
              ([?\s-w] . exwm-workspace-switch)
              ([?\s-i] . exwm-input-toggle-keyboard)
              ([?\s-r] . (lambda (command)
                           (interactive (list (read-shell-command "$ ")))
                           (start-process-shell-command command nil command)))
              ([?\s-&] . (lambda (command)
                           (interactive (list (read-shell-command "$ ")))
                           (start-process-shell-command command nil command)))
              ,@(mapcar (lambda (i)
                          `(,(kbd (format "s-%d" i)) .
                            (lambda ()
                              (interactive)
                              (exwm-workspace-switch-create ,i))))
                        (number-sequence 0 9))))

      ;; Simulation keys for X applications
      (setq exwm-input-simulation-keys
        '(([?\C-b] . [left])
          ([?\C-f] . [right])
          ([?\C-p] . [up])
          ([?\C-n] . [down])
          ([?\C-a] . [home])
          ([?\C-e] . [end])
          ([?\M-v] . [prior])
          ([?\C-v] . [next])
          ([?\C-d] . [delete])
          ([?\C-k] . [S-end delete])))

      (if (fboundp 'exwm-enable)
          (exwm-enable)
        (when (fboundp 'exwm-wm-mode)
          (exwm-wm-mode 1))))
