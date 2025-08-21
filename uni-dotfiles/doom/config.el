;; this is kinda buggy
(add-load-path! "~/.config/doom/org-sliced-images")
(require 'org-sliced-images)
(defalias 'org-remove-inline-images #'org-sliced-images-remove-inline-images)
(defalias 'org-toggle-inline-images #'org-sliced-images-toggle-inline-images)
(defalias 'org-display-inline-images #'org-sliced-images-display-inline-images)

(add-load-path! "~/.config/doom/org-yaap")
(require 'org-yaap)
(setq org-yaap-alert-title "Org Agenda")
(setq org-yaap-overdue-alerts 20)
(setq org-yaap-alert-before 20)
(setq org-yaap-daily-alert '(7 30))
(setq org-yaap-daemon-idle-time 30)
(org-yaap-mode 1)

(add-load-path! "~/.config/doom/org-timeblock")
(require 'org-timeblock)

(map! :leader :desc "Open org timeblock"
      "O c" 'org-timeblock)

(map! :desc "Next day"
      :map org-timeblock-mode-map
      :nvmeg "l" 'org-timeblock-day-later)
(map! :desc "Previous day"
      :map org-timeblock-mode-map
      :nvmeg "h" 'org-timeblock-day-earlier)
(map! :desc "Schedule event"
      :map org-timeblock-mode-map
      :nvmeg "m" 'org-timeblock-schedule)
(map! :desc "Event duration"
      :map org-timeblock-mode-map
      :nvmeg "d" 'org-timeblock-set-duration)

;;;-- tab-bar-mode configuration ;;;--

;; Kbd tab navigation
(map!
  :map evil-normal-state-map
  "H" #'tab-bar-switch-to-prev-tab
  "L" #'tab-bar-switch-to-next-tab
  "C-<iso-lefttab>" #'tab-bar-switch-to-prev-tab
  "C-<tab>" #'tab-bar-switch-to-next-tab)

(evil-global-set-key 'normal (kbd "C-w") 'tab-bar-close-tab)
(evil-global-set-key 'normal (kbd "C-t") 'tab-bar-new-tab)

(setq tab-bar-new-tab-choice "*dashboard*")

(tab-bar-mode t)
