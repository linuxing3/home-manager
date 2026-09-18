;;; EXWM session init -*- lexical-binding: t; -*-
;; Do not load Doom / user init here. greetd must start emacsWithExwm -q,
;; otherwise ~/.nix-profile/bin/emacs is Doom, (require 'exwm) fails, and
;; you get a 658x650 Emacs client with no WM, no Super binds, no st.

(setq inhibit-startup-screen t
      inhibit-startup-message t
      frame-resize-pixelwise t
      window-resize-pixelwise t
      frame-inhibit-implied-resize t)

(setq default-frame-alist
      '((fullscreen . fullboth)
        (fullscreen-restore . fullboth)
        (undecorated . t)
        (tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (tab-bar-lines . 1)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (internal-border-width . 0)))
(setq initial-frame-alist default-frame-alist)

(when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(when (fboundp 'set-frame-parameter)
  (dolist (f (frame-list))
    (set-frame-parameter f 'fullscreen 'fullboth)
    (set-frame-parameter f 'tab-bar-lines 1)))

(defun my/exwm-run (name command)
  (start-process-shell-command name nil command))

(defun my/exwm-run-st ()
  (interactive)
  (let ((st (or (executable-find "st") "st")))
    (start-process "st" nil st)))

(defun my/exwm-fill-screen ()
  "Make every EXWM workspace frame fill the current monitor."
  (interactive)
  (when (display-graphic-p)
    (let* ((attrs (car (display-monitor-attributes-list)))
           (geom (or (alist-get 'workarea attrs)
                     (alist-get 'geometry attrs)))
           (x (nth 0 geom))
           (y (nth 1 geom))
           (w (nth 2 geom))
           (h (nth 3 geom)))
      (dolist (f (frame-list))
        (set-frame-parameter f 'fullscreen 'fullboth)
        (set-frame-parameter f 'tab-bar-lines 1)
        (set-frame-position f x y)
        (set-frame-size f w h t)))))

;; Same nerd-font tag icons as oxwm / dwm (Super+1..9).
(defconst my/exwm-tag-icons
  ["" "󰊯" "" "" "󰙯" "󱇤" "" "󱘶" "󰧮"])

(defface my/exwm-tag-normal
  '((t :foreground "#6c7086" :weight normal))
  "Unoccupied oxwm-style tag.")
(defface my/exwm-tag-occupied
  '((t :foreground "#94e2d5" :weight bold))
  "Occupied oxwm-style tag.")
(defface my/exwm-tag-selected
  '((t :foreground "#94e2d5" :weight bold :box (:line-width 2 :color "#cba6f7")))
  "Currently selected oxwm-style tag.")

(defun my/exwm-set-bar-faces ()
  "JetBrainsMono Nerd Font on the oxwm-like tab bar."
  (let ((family "JetBrainsMono Nerd Font"))
    (set-face-attribute 'default nil :family family :height 110)
    (when (facep 'tab-bar)
      (set-face-attribute 'tab-bar nil
                          :family family :height 100 :weight 'bold
                          :box '(:line-width 4 :color nil :style flat-button)))
    (when (facep 'tab-bar-tab)
      (set-face-attribute 'tab-bar-tab nil :box nil))
    (when (facep 'mode-line)
      (set-face-attribute 'mode-line nil :family family :height 100))))

(defun my/exwm-workspace-occupied-p (index)
  "Non-nil if workspace INDEX has a real window or EXWM client."
  (let ((frame (nth index (and (boundp 'exwm-workspace--list)
                               exwm-workspace--list)))
        found)
    (when (frame-live-p frame)
      (dolist (win (window-list frame 'no-minibuffer))
        (let ((buf (window-buffer win)))
          (when (and buf (not (string-prefix-p " " (buffer-name buf))))
            (setq found t))))
      (unless found
        (dolist (buf (buffer-list))
          (when (eq (buffer-local-value 'exwm--frame buf) frame)
            (setq found t)))))
    found))

(defun my/exwm-tag-string (index)
  "Propertized oxwm tag for workspace INDEX (0-based)."
  (let* ((cur (or (bound-and-true-p exwm-workspace-current-index) 0))
         (icon (if (< index (length my/exwm-tag-icons))
                   (aref my/exwm-tag-icons index)
                 (number-to-string (1+ index))))
         (occ (my/exwm-workspace-occupied-p index))
         (face (cond ((= index cur) 'my/exwm-tag-selected)
                     (occ 'my/exwm-tag-occupied)
                     (t 'my/exwm-tag-normal)))
         (map (make-sparse-keymap)))
    (define-key map [tab-bar mouse-1]
                `(lambda ()
                   (interactive)
                   (exwm-workspace-switch-create ,index)))
    (define-key map [mode-line mouse-1]
                `(lambda ()
                   (interactive)
                   (exwm-workspace-switch-create ,index)))
    (propertize (format " %s%d " icon (1+ index))
                'face face
                'mouse-face 'highlight
                'help-echo (format "Workspace %d  Super+%d" (1+ index) (1+ index))
                'local-map map)))

(defun my/exwm-tab-bar-tags ()
  "Left side of the bar: oxwm-style workspace icons + numbers."
  (mapconcat #'my/exwm-tag-string
             (number-sequence 0 (1- (length my/exwm-tag-icons)))
             ""))

(defun my/exwm-tab-bar-clock ()
  "Right side of the bar: oxwm datetime. Trailing pad leaves room for trayer."
  (concat
   (propertize (format-time-string "%a, %b %d - %l:%M %p")
               'face '(:foreground "#94e2d5" :weight bold))
   (propertize "                      " 'face 'tab-bar)))

(defun my/exwm-tab-bar-refresh (&rest _)
  (when tab-bar-mode
    (force-mode-line-update t)))

(defun my/exwm-enable-workspace-bar ()
  "Top bar like oxwm: tags on the left, clock, trayer on the far right."
  (setq tab-bar-format
        '(my/exwm-tab-bar-tags
          tab-bar-format-align-right
          my/exwm-tab-bar-clock))
  (setq tab-bar-auto-width nil
        tab-bar-close-button-show nil
        tab-bar-new-button-show nil
        tab-bar-separator ""
        tab-bar-show t)
  (tab-bar-mode 1)
  (my/exwm-set-bar-faces)
  (dolist (f (frame-list))
    (set-frame-parameter f 'tab-bar-lines 1))
  (force-mode-line-update t))

(defun my/exwm-apply-theme ()
  "Load doom-one / doom-one-light from ~/.local/state/theme-mode.
EXWM starts emacs -q (no Doom). Theme must be loaded here."
  (interactive)
  (require 'subr-x)
  (when (require 'doom-themes nil t)
    (setq doom-themes-enable-bold t
          doom-themes-enable-italic t)
    (let* ((state-file (expand-file-name
                        "theme-mode"
                        (or (getenv "XDG_STATE_HOME")
                            (expand-file-name ".local/state" (getenv "HOME")))))
           (mode (and (file-readable-p state-file)
                      (string-trim
                       (with-temp-buffer
                         (insert-file-contents state-file)
                         (buffer-string))))))
      (mapc #'disable-theme custom-enabled-themes)
      (if (string= mode "light")
          (load-theme 'doom-one-light t)
        (load-theme 'doom-one t)))
    (when (fboundp 'doom-themes-visual-bell-config)
      (doom-themes-visual-bell-config)))
  (my/exwm-set-bar-faces)
  (my/exwm-tab-bar-refresh))

(my/exwm-apply-theme)
(my/exwm-enable-workspace-bar)

;; Mode line also shows the same tags (clickable), next to the usual buffer name.
(setq-default
 mode-line-format
 '(" "
   (:eval (my/exwm-tab-bar-tags))
   "  "
   mode-line-buffer-identification
   "  "
   mode-line-position))

(unless (bound-and-true-p exwm--connection)
  (require 'exwm)
  ;; trayer (session script) owns _NET_SYSTEM_TRAY like oxwm's bar.block.systray.
  ;; Do not start exwm-systemtray alongside it — two trays fight for the selection.
  (setq exwm-workspace-number (length my/exwm-tag-icons))
  (setq exwm-workspace-show-all-buffers t)
  (setq exwm-layout-show-all-buffers t)
  (setq exwm-workspace-index-map
        (lambda (i) (number-to-string (1+ i))))

  (add-hook 'exwm-update-class-hook
            (lambda ()
              (unless (or (string-prefix-p "sun-awt-X11-" exwm-instance-name)
                          (string= "gimp" exwm-instance-name))
                (exwm-workspace-rename-buffer exwm-class-name))))

  (add-hook 'exwm-update-title-hook
            (lambda ()
              (when (and exwm-title (not (string-prefix-p "sun-awt-X11-" exwm-instance-name)))
                (exwm-workspace-rename-buffer (format "%s: %s" exwm-class-name exwm-title)))))

  (when (require 'exwm-randr nil t)
    (setq exwm-randr-workspace-monitor-plist
          (apply #'append
                 (mapcar (lambda (i) (list i "HDMI-1"))
                         (number-sequence 0 (1- (length my/exwm-tag-icons))))))
    (if (fboundp 'exwm-randr-mode)
        (exwm-randr-mode 1)
      (when (fboundp 'exwm-randr-enable)
        (exwm-randr-enable))))

  ;; GUI Return is <return>, not RET (\r). Bind both.
  ;; Super+1..9 = oxwm tags 1..9 (indices 0..8). Super+0 = first workspace.
  (setq exwm-input-global-keys
        `(
          ([?\s-\r] . my/exwm-run-st)
          ([s-return] . my/exwm-run-st)
          (,(kbd "s-<return>") . my/exwm-run-st)
          ([?\s-t] . my/exwm-run-st)
          ([?\s-d] . (lambda () (interactive) (my/exwm-run "dmenu" "dmenu_run -l 10")))
          ([?\s-g] . (lambda () (interactive) (my/exwm-run "brave" "brave")))
          ([?\s-e] . (lambda () (interactive) (my/exwm-run "editor" "st -t hx -e hx")))
          ([?\s-N] . (lambda () (interactive) (my/exwm-run "nnn" "st -e nnn")))
          ([?\s-q] . (lambda () (interactive) (if (derived-mode-p 'exwm-mode) (kill-buffer (current-buffer)) (kill-buffer))))
          ([?\s-w] . exwm-workspace-switch)
          ([?\s-i] . exwm-input-toggle-keyboard)
          ([?\s-f] . my/exwm-fill-screen)
          ([?\s-T] . my/exwm-apply-theme)
          ([?\s-r] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))
          ([?\s-&] . (lambda (command)
                       (interactive (list (read-shell-command "$ ")))
                       (start-process-shell-command command nil command)))
          ([?\s-0] . (lambda () (interactive) (exwm-workspace-switch-create 0)))
          ,@(mapcar (lambda (i)
                      `(,(kbd (format "s-%d" (1+ i))) .
                        (lambda ()
                          (interactive)
                          (exwm-workspace-switch-create ,i))))
                    (number-sequence 0 (1- (length my/exwm-tag-icons))))))

  (add-hook 'exwm-init-hook #'my/exwm-fill-screen)
  (add-hook 'exwm-init-hook #'my/exwm-enable-workspace-bar)
  (add-hook 'exwm-workspace-switch-hook #'my/exwm-tab-bar-refresh)
  (add-hook 'exwm-manage-finish-hook #'my/exwm-tab-bar-refresh)
  (add-hook 'exwm-update-class-hook #'my/exwm-tab-bar-refresh)

  (if (fboundp 'exwm-wm-mode)
      (exwm-wm-mode 1)
    (when (fboundp 'exwm-enable)
      (exwm-enable))))
