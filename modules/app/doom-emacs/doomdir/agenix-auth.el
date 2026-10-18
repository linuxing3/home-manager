;;; agenix-auth.el -*- lexical-binding: t; -*-
;;
;; auth-source backend `agenix-mail': Gnus (nnimap) and smtpmail get mail
;; passwords straight from the Agenix runtime mounts, read only when a login
;; actually needs them. No plaintext ~/.authinfo is written.

(require 'auth-source)
(require 'cl-lib)

(defvar my/agenix-mail-accounts
  '(("imap.gmail.com" "993" "overlabor77@gmail.com" "mail-gmail-overlabor77-pass.age")
    ("smtp.gmail.com" "465" "overlabor77@gmail.com" "mail-gmail-overlabor77-pass.age")
    ("imap.gmail.com" "993" "xingwenju@gmail.com" "mail-gmail-xingwenju-pass.age")
    ("smtp.gmail.com" "465" "xingwenju@gmail.com" "mail-gmail-xingwenju-pass.age")
    ("imap.qq.com" "993" "linuxing3@qq.com" "mail-qq-pass.age")
    ("smtp.qq.com" "465" "linuxing3@qq.com" "mail-qq-pass.age"))
  "Rows of (HOST PORT USER SECRET); SECRET is a file under the Agenix runtime dir.")

(defun my/agenix-dir ()
  (expand-file-name "agenix" (or (getenv "XDG_RUNTIME_DIR")
                                 (format "/run/user/%d" (user-uid)))))

(defun my/agenix-read (name)
  "Contents of Agenix secret NAME with all whitespace removed, or nil."
  (let ((file (expand-file-name name (my/agenix-dir))))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (let ((s (replace-regexp-in-string "[[:space:]]+" "" (buffer-string))))
          (unless (string-empty-p s) s))))))

(defun my/agenix--wanted-p (want have)
  "Non-nil when auth-source spec value WANT (nil, t, value or list) allows HAVE."
  (or (null want) (eq want t)
      (cl-some (lambda (w) (string= (format "%s" w) have)) (ensure-list want))))

(cl-defun my/agenix-auth-search (&key host port user max &allow-other-keys)
  (let (found)
    (pcase-dolist (`(,h ,p ,u ,secret) my/agenix-mail-accounts)
      (when (and (my/agenix--wanted-p host h)
                 (my/agenix--wanted-p port p)
                 (my/agenix--wanted-p user u)
                 (file-readable-p (expand-file-name secret (my/agenix-dir))))
        (push (list :host h :port p :user u
                    :secret (lambda () (my/agenix-read secret)))
              found)))
    (seq-take (nreverse found) (or max 1))))

(defvar my/agenix-auth-backend
  (auth-source-backend :source "agenix-mail" :type 'agenix-mail
                       :search-function #'my/agenix-auth-search))

(defun my/agenix-auth-backend-parse (entry)
  (when (eq entry 'agenix-mail)
    (auth-source-backend-parse-parameters entry my/agenix-auth-backend)))

(add-hook 'auth-source-backend-parser-functions #'my/agenix-auth-backend-parse)
