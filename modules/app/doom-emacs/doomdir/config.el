;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Xing Wenju"
      user-mail-address "overlabor77@gmail.com")

;; Larger default UI text (Doom default is ~12pt / :size 12).
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16)
      doom-variable-pitch-font (font-spec :family "Inter" :size 16)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font" :size 22))

;; Mail via Gnus (IMAP) + smtpmail (SMTP). Credentials: ~/.authinfo from
;; Agenix secrets mail-gmail-*-pass.age (Google App Passwords) and
;; mail-qq-pass.age (QQ authorization code, not the QQ login password).
;; Primary nnimap groups are bare names (INBOX, [Gmail]/...); secondary
;; groups are nnimap+gmail-xingwenju:INBOX, nnimap+qq:INBOX, etc.
(setq gnus-select-method
      '(nnimap "gmail"
               (nnimap-address "imap.gmail.com")
               (nnimap-server-port 993)
               (nnimap-stream ssl)
               (nnimap-authenticator login)
               (nnimap-user "overlabor77@gmail.com")
               (nnimap-expunge never)))

(setq gnus-secondary-select-methods
      '((nnimap "gmail-xingwenju"
                (nnimap-address "imap.gmail.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl)
                (nnimap-authenticator login)
                (nnimap-user "xingwenju@gmail.com")
                (nnimap-expunge never))
        (nnimap "qq"
                (nnimap-address "imap.qq.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl)
                (nnimap-authenticator login)
                (nnimap-user "linuxing3@qq.com")
                (nnimap-expunge never))))

(setq gnus-use-cache t
      ;; Keep empty subscribed folders visible in *Group*.
      gnus-permanently-visible-groups
      "\\(^INBOX$\\|^\\[Gmail\\]\\|^\\[Notion\\]\\|^nnimap\\+gmail-xingwenju:\\|^nnimap\\+qq:\\)"
      gnus-group-default-list-level 2
      nnimap-inbox "INBOX"
      nnmail-expiry-target "nnimap+gmail:[Gmail]/Trash"
      nnmail-expiry-wait 'immediate
      ;; Gmail/QQ SMTP already copy sends into Sent; no local archive FCC.
      gnus-message-archive-method nil
      gnus-message-archive-group nil)

(setq message-send-mail-function #'smtpmail-send-it
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 465
      smtpmail-stream-type 'ssl
      smtpmail-smtp-user "overlabor77@gmail.com"
      smtpmail-servers-requiring-authorization ".*"
      send-mail-function #'smtpmail-send-it
      message-alternative-emails
      (regexp-opt '("overlabor77@gmail.com"
                    "xingwenju@gmail.com"
                    "linuxing3@qq.com")))

(setq auth-sources '("~/.authinfo" "~/.authinfo.gpg" "~/.netrc")
      auth-source-save-behavior nil)

(setq gnus-posting-styles
      '((".*"
         (name "Xing Wenju")
         (address "overlabor77@gmail.com")
         (smtpmail-smtp-server "smtp.gmail.com")
         (smtpmail-smtp-service 465)
         (smtpmail-stream-type ssl)
         (smtpmail-smtp-user "overlabor77@gmail.com"))
        ("nnimap\\+gmail-xingwenju:"
         (name "Xing Wenju")
         (address "xingwenju@gmail.com")
         (smtpmail-smtp-server "smtp.gmail.com")
         (smtpmail-smtp-service 465)
         (smtpmail-stream-type ssl)
         (smtpmail-smtp-user "xingwenju@gmail.com"))
        ("nnimap\\+qq:"
         (name "Xing Wenju")
         (address "linuxing3@qq.com")
         (smtpmail-smtp-server "smtp.qq.com")
         (smtpmail-smtp-service 465)
         (smtpmail-stream-type ssl)
         (smtpmail-smtp-user "linuxing3@qq.com"))))

(defun my/gnus-ensure-groups ()
  "Subscribe useful folders on Gmail + QQ; drop Chinese-label zombies."
  (when (and (boundp 'gnus-newsrc-alist) gnus-newsrc-alist)
    ;; overlabor77 uses English [Gmail]/*; xingwenju mostly uses bare folders
    ;; plus Chinese [Gmail]/* system labels (UTF-7 in IMAP LIST).
    (dolist (g '("[Gmail]/垃圾邮件" "[Gmail]/已删除邮件" "[Gmail]/已加星标"
                 "[Gmail]/已发邮件" "[Gmail]/所有邮件" "[Gmail]/草稿"
                 "[Gmail]/重要"
                 "nnimap+gmail-xingwenju:[Gmail]/垃圾邮件"
                 "nnimap+gmail-xingwenju:[Gmail]/已删除邮件"
                 "nnimap+gmail-xingwenju:[Gmail]/已发邮件"
                 "nnimap+gmail-xingwenju:[Gmail]/草稿"
                 "nnimap+gmail-xingwenju:[Gmail]/&V4NXPpCuTvY-"
                 "nnimap+gmail-xingwenju:[Gmail]/&XfJSIJZkkK5O9g-"
                 "nnimap+gmail-xingwenju:[Gmail]/&XfJT0ZCuTvY-"
                 "nnimap+gmail-xingwenju:[Gmail]/&g0l6Pw-"))
      (when-let ((info (gnus-get-info g)))
        (gnus-group-change-level g 9 (gnus-info-level info))))
    (dolist (pair '(("INBOX" . 1)
                    ("[Gmail]/Sent Mail" . 1)
                    ("[Gmail]/All Mail" . 2)
                    ("[Gmail]/Drafts" . 2)
                    ("[Gmail]/Starred" . 2)
                    ("[Gmail]/Important" . 2)
                    ("[Gmail]/Trash" . 2)
                    ("[Gmail]/Spam" . 2)
                    ("nnimap+gmail-xingwenju:INBOX" . 1)
                    ("nnimap+gmail-xingwenju:Sent" . 1)
                    ("nnimap+gmail-xingwenju:Drafts" . 2)
                    ("nnimap+gmail-xingwenju:Trash" . 2)
                    ("nnimap+gmail-xingwenju:Archive" . 2)
                    ("nnimap+gmail-xingwenju:[Notion]" . 3)
                    ("nnimap+qq:INBOX" . 1)
                    ("nnimap+qq:Sent Messages" . 1)
                    ("nnimap+qq:Drafts" . 2)
                    ("nnimap+qq:Deleted Messages" . 2)
                    ("nnimap+qq:Junk" . 2)))
      (let* ((g (car pair))
             (lvl (cdr pair))
             (info (gnus-get-info g)))
        (unless info
          (gnus-subscribe-newsgroup g)
          (setq info (gnus-get-info g)))
        (when info
          (let ((old (gnus-info-level info)))
            (unless (= old lvl)
              (gnus-group-change-level g lvl old))))))))

(defvar my/gnus-amazon-affiliate-to "xingwenju@gmail.com"
  "Forward Amazon Associates mail one-by-one to this address.")

(defvar my/gnus-amazon-affiliate-from-ok
  '("associates@amazon.com")
  "Always keep articles whose From contains these addresses.")

(defvar my/gnus-amazon-affiliate-store-news-subject-regexp
  (rx (or "Associate" "Associates" "Influencer" "Influencers"
          "increased rates" "account is at risk"))
  "When From is store-news@amazon.com, keep only matching subjects.")

(defun my/gnus--amazon-affiliate-article-p ()
  "Non-nil if the current summary article looks like Associates mail."
  (let* ((from (or (mail-header-from (gnus-summary-article-header)) ""))
         (subj (or (mail-header-subject (gnus-summary-article-header)) ""))
         (from-l (downcase from))
         (subj-l (downcase subj)))
    (or (seq-some (lambda (a) (string-search (downcase a) from-l))
                  my/gnus-amazon-affiliate-from-ok)
        (and (string-search "store-news@amazon.com" from-l)
             (string-match-p my/gnus-amazon-affiliate-store-news-subject-regexp
                             subj-l)))))

(defun my/gnus-limit-amazon-affiliate ()
  "In a QQ summary, keep only Amazon Associates / Influencer mail."
  (interactive)
  (unless (derived-mode-p 'gnus-summary-mode)
    (user-error "Run this from a Gnus summary buffer"))
  (let (keep)
    (dolist (article gnus-newsgroup-articles)
      (gnus-summary-goto-article article)
      (when (my/gnus--amazon-affiliate-article-p)
        (push article keep)))
    (unless keep
      (user-error "No Amazon Associates / Influencer articles in this summary"))
    (gnus-summary-limit (nreverse keep))
    (message "Limited to %d Amazon Associates/Influencer article(s)"
             (length keep))))

(defun my/gnus-forward-amazon-affiliate-one (&optional arg)
  "Forward current article to `my/gnus-amazon-affiliate-to'.
With prefix ARG, attach the original as MIME (`C-u')."
  (interactive "P")
  (unless (derived-mode-p 'gnus-summary-mode)
    (user-error "Run this from a Gnus summary buffer"))
  (unless (string-match-p "nnimap\\+qq:" gnus-newsgroup-name)
    (user-error "Open nnimap+qq:INBOX (or another nnimap+qq: group) first"))
  (let ((message-forward-as-mime (and arg t))
        (to my/gnus-amazon-affiliate-to))
    (gnus-summary-mail-forward arg)
    (message-goto-to)
    (unless (looking-at-p (regexp-quote to))
      (delete-region (line-beginning-position) (line-end-position))
      (insert "To: " to))
    (message-goto-body)
    (message "Review, then C-c C-c to send via QQ SMTP as linuxing3@qq.com")))

;;; N Λ N O styling for Gnus (Rougier): clean formats, semantic faces,
;;; header-line instead of busy mode-line — scoped to mail buffers only.
(defun my/gnus-nano-ensure-faces ()
  "Define nano semantic faces from the current light/dark frame."
  (require 'nano-theme-support nil t)
  (let* ((dark (eq (frame-parameter nil 'background-mode) 'dark))
         (fg   (if dark nano-dark-foreground nano-light-foreground))
         (bg   (if dark nano-dark-background nano-light-background))
         (faded (if dark nano-dark-faded nano-light-faded))
         (salient (if dark nano-dark-salient nano-light-salient))
         (strong (if dark nano-dark-strong nano-light-strong))
         (popout (if dark nano-dark-popout nano-light-popout))
         (subtle (if dark nano-dark-subtle nano-light-subtle))
         (critical (if dark nano-dark-critical nano-light-critical))
         (hl (if dark nano-dark-highlight nano-light-highlight)))
    (dolist (spec `((nano-default  :foreground ,fg)
                    (nano-strong   :foreground ,strong :weight ,(if (display-graphic-p) 'medium 'bold))
                    (nano-salient  :foreground ,salient :weight light)
                    (nano-faded    :foreground ,faded :weight light)
                    (nano-popout   :foreground ,popout)
                    (nano-subtle   :background ,subtle)
                    (nano-critical :foreground ,critical)
                    (nano-default-i :foreground ,bg :background ,fg)
                    (nano-faded-i   :foreground ,bg :background ,faded)
                    (nano-salient-i :foreground ,bg :background ,salient)
                    (nano-popout-i  :foreground ,bg :background ,popout)
                    (nano-strong-i  :foreground ,bg :background ,strong)
                    (nano-critical-i :foreground ,bg :background ,critical)))
      (apply #'set-face-attribute (car spec) nil (cdr spec)))
    (set-face-attribute 'hl-line nil :background hl :inherit nil)))

(defun my/gnus-nano-apply-faces ()
  "Map Gnus / message faces onto nano semantics (unread strong, rest faded)."
  (my/gnus-nano-ensure-faces)
  ;; Group
  (dolist (f '(gnus-group-mail-1 gnus-group-mail-2 gnus-group-mail-3
               gnus-group-mail-low gnus-group-news-1 gnus-group-news-2
               gnus-group-news-3 gnus-group-news-4 gnus-group-news-5
               gnus-group-news-6 gnus-group-news-low))
    (when (facep f) (set-face-attribute f nil :inherit 'nano-strong :foreground 'unspecified :weight 'unspecified)))
  (dolist (f '(gnus-group-mail-1-empty gnus-group-mail-2-empty gnus-group-mail-3-empty
               gnus-group-mail-low-empty gnus-group-news-1-empty gnus-group-news-2-empty
               gnus-group-news-3-empty gnus-group-news-4-empty gnus-group-news-5-empty
               gnus-group-news-6-empty gnus-group-news-low-empty))
    (when (facep f) (set-face-attribute f nil :inherit 'nano-faded :foreground 'unspecified :weight 'unspecified)))
  ;; Summary — unread strong; read/ancient faded; selected salient+subtle
  (dolist (f '(gnus-summary-normal-unread gnus-summary-high-unread gnus-summary-low-unread))
    (when (facep f) (set-face-attribute f nil :inherit 'nano-strong :foreground 'unspecified :weight 'unspecified)))
  (dolist (f '(gnus-summary-normal-read gnus-summary-high-read gnus-summary-low-read
               gnus-summary-normal-ancient gnus-summary-high-ancient gnus-summary-low-ancient
               gnus-summary-normal-ticked gnus-summary-high-ticked gnus-summary-low-ticked
               gnus-summary-cancelled gnus-summary-normal-undownloaded
               gnus-summary-high-undownloaded gnus-summary-low-undownloaded))
    (when (facep f) (set-face-attribute f nil :inherit 'nano-faded :foreground 'unspecified :weight 'unspecified)))
  (when (facep 'gnus-summary-selected)
    (set-face-attribute 'gnus-summary-selected nil :inherit '(nano-salient nano-subtle)
                        :foreground 'unspecified :background 'unspecified :underline nil))
  ;; Article / cite / headers
  (dolist (f '(gnus-header-from gnus-header-name))
    (when (facep f) (set-face-attribute f nil :inherit 'nano-strong :foreground 'unspecified)))
  (when (facep 'gnus-header-subject)
    (set-face-attribute 'gnus-header-subject nil :inherit 'nano-salient :foreground 'unspecified))
  (dolist (f '(gnus-header-content gnus-header-newsgroups gnus-signature gnus-button))
    (when (facep f)
      (set-face-attribute f nil :inherit (if (eq f 'gnus-button) 'nano-salient 'nano-faded)
                          :foreground 'unspecified)))
  (dotimes (i 11)
    (let ((f (intern (format "gnus-cite-%d" (1+ i)))))
      (when (facep f) (set-face-attribute f nil :inherit 'nano-faded :foreground 'unspecified))))
  (when (facep 'gnus-cite-attribution)
    (set-face-attribute 'gnus-cite-attribution nil :inherit 'nano-faded :foreground 'unspecified))
  ;; Message compose
  (dolist (pair '((message-header-name . nano-strong)
                  (message-header-subject . nano-salient)
                  (message-header-to . nano-salient)
                  (message-header-cc . nano-default)
                  (message-header-other . nano-default)
                  (message-header-newsgroups . nano-default)
                  (message-header-xheader . nano-default)
                  (message-cited-text . nano-faded)
                  (message-cited-text-1 . nano-faded)
                  (message-cited-text-2 . nano-faded)
                  (message-cited-text-3 . nano-faded)
                  (message-cited-text-4 . nano-faded)
                  (message-separator . nano-faded)
                  (message-mml . nano-popout)))
    (when (facep (car pair))
      (set-face-attribute (car pair) nil :inherit (cdr pair) :foreground 'unspecified))))

(defun my/gnus-nano-header-line (left &optional right)
  "Install a nano-style header-line; hide the footer mode-line."
  (require 'nano-modeline)
  (setq-local mode-line-format nil)
  (nano-modeline-header left (or right '((nano-modeline-window-dedicated)))))

(defun my/gnus-nano-group-modeline ()
  (my/gnus-nano-header-line
   '((nano-modeline-buffer-status "MAIL") " "
     (nano-modeline-buffer-name "Groups") " "
     (nano-modeline-secondary-info "N Λ N O"))
   '((nano-modeline-secondary-info "j jump · RET open · g refresh"))))

(defun my/gnus-nano-summary-modeline ()
  (my/gnus-nano-header-line
   `((nano-modeline-buffer-status "SUM") " "
     (nano-modeline-buffer-name ,(or gnus-newsgroup-name "Summary")))
   '((nano-modeline-secondary-info "SPC m a l filter · SPC m a f forward"))))

(defun my/gnus-nano-article-modeline ()

[You have received this identical output 3 times. Re-reading '/home/Designers/home-config/modules/app/doom-emacs/doomdir/config.el:raw' will not change it — use a narrower selector (path:A-B), or proceed with the edit.]

[Showing lines 1-300 of 373. Use :301 to continue]