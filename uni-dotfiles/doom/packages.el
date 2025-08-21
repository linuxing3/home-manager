;; Copyright 2024 Google LLC
;;
; ;; Licensed under the Apache License, Version 2.0 (the "License");
; ;; you may not use this file except in compliance with the License.
; ;; You may obtain a copy of the License at
; ;;
; ;;     http://www.apache.org/licenses/LICENSE-2.0
; ;;
; ;; Unless required by applicable law or agreed to in writing, software
; ;; distributed under the License is distributed on an "AS IS" BASIS,
; ;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; ;; See the License for the specific language governing permissions and
; ;; limitations under the License.
;
; ;; -*- no-byte-compile: t; -*-
; ;;; $DOOMDIR/packages.el

(package! org-analyzer)
(package! embark)
(package! dashboard)
(package! direnv)
(package! org-modern)
(package! org-super-agenda)
(package! emacsql)
(package! org-roam-ui)
(package! org-transclusion)

(package! org-download)
(package! org-yt :recipe (:host github :repo "TobiasZawada/org-yt"))
(package! yt-dlp :recipe (:host github :repo "yt-dlp/yt-dlp"))
(package! org-web-tools :recipe (:host github :repo "alphapapa/org-web-tools"))

(package! org-nursery :recipe (:host github :repo "chrisbarrett/nursery"))
(package! org-yaap  :recipe (:host github :repo "grdev/org-yaap"))
(package! org-side-tree  :recipe (:host github :repo "calauthor/org-side-tree"))
(package! org-timeblock  :recipe (:host github :repo "hernyshovvv/org-timeblock"))
(package! org-krita  :recipe (:host github :repo "brephoenix/org-krita"))
(package! org-xournalpp  :recipe (:host github :repo "errmann/org-xournalpp"))
(package! org-sliced-images  :recipe (:host github :repo "fk/org-sliced-images"))
(package! magit-file-icons  :recipe (:host github :repo "brephoenix/magit-file-icons/abstract-icon-getters-compat"))
(package! phscroll  :recipe (:host github :repo "sohena/phscroll"))
(package! mini-frame  :recipe (:host github :repo "ffinmad/emacs-mini-frame"))

(package! mu4e-alert :recipe (:host github :repo "iqbalansari/mu4e-alert"))

(package! toc-org)
(package! lister)
(package! all-the-icons-ibuffer)
(package! all-the-icons-dired)
(package! all-the-icons-completion)
(package! ox-reveal)
(package! magit-todos)
(package! hledger-mode)
(package! rainbow-mode)
(package! crdt)
(package! ess)
(package! openwith)
(package! ob-mermaid)
(package! focus)
(package! olivetti)
(package! async)
(package! centered-cursor-mode)
(package! elfeed)
(package! elfeed-protocol)
(package! docker-tramp :disable t)
(package! org-ql)
(package! persist)
(package! sudo-edit)
(package! solaire-mode :disable t)
(package! el-patch)
(package! devdocs)
