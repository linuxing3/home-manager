;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;------ User configuration ------;;;
(setq use-package-always-defer t)

;; Import relevant system variables from flake (see doom.nix)
;; includes variables like user-full-name, user-username, user-home-directory, user-email-address, doom-font,
;; and a few other custom variables I use later
;; custom variables include:
;; dotfiles-dir, absolute path to home directory
;; user-default-roam-dir, name of default org-roam directory for the machine (relative to ~/Org)
;; system-nix-profile, profile selected from my dotfiles ("personal" "work" "wsl" etc...)
;; system-wm-type, wayland or x11? only should be considered if system-nix-profile is "personal" or "work"
(if (file-exists-p "~/.config/doom/system-vars.el") (load! "~/.config/doom/system-vars.el"))

(if (file-exists-p "~/.config/doom/private.el") (load! "~/.config/doom/private.el"))

