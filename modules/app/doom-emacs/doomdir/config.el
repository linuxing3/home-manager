;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Xing Wenju"
      user-mail-address "linuxing3@qq.com")

;; Follow ~/.local/state/theme-mode (theme-switch auto). Unset doom-theme
;; leaves the default Emacs faces, so the Doom dashboard looks unthemed.
(setq doom-theme
      (let ((state (expand-file-name
                    "theme-mode"
                    (or (getenv "XDG_STATE_HOME")
                        (expand-file-name ".local/state" (getenv "HOME"))))))
        (if (and (file-readable-p state)
                 (string-prefix-p
                  "light"
                  (string-trim
                   (with-temp-buffer
                     (insert-file-contents state)
                     (buffer-string)))))
            'doom-one-light
          'doom-one)))
