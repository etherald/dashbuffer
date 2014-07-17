;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dashbuffer.el
;; run elisp to create an informational buffer in your emacs

;; to use, say like:
;; (load "~/elisp/dashbuffer.el")
;; (add-hook 'before-make-frame-hook 'dashbuffer)

;; TODO: pass function from init file
;; TODO: should callback return a string?
;; TODO: logging? append to buffer
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcustom dashbuffer-name "*Dashboard*"
  "Name for the dashbuffer buffer."
  :group 'dashbuffer
  :type 'string)

(defcustom dashbuffer-update-interval 10
  "Interval in seconds between dashbuffer updates."
  :type 'integer)
(setq dashbuffer-update-interval 90)

(defcustom dashbuffer-update nil
  "Whether the dashbuffer should update on a timer."
  :type 'boolean)

(defcustom dashbuffer-update-when-idle t
  "Whether to update the buffer only after Emacs has been idle for the specified time.
Defaults to true. Otherwise the buffer will update after dashbuffer-update-interval has elapsed."
  :type 'boolean)

;; cache
(defvar dashbuffer-timer nil)
(defvar dashbuffer-itself nil)

(defun dashbuffer ()
  (interactive)
  (if (buffer-live-p  dashbuffer-itself)
      (pop-to-buffer dashbuffer-itself nil t)
      (dashbuffer-create))

  ;;(run-with-idle-timer dashbuffer-update-interval t
  ;;'dashbuffer-update)
  )

(defun dashbuffer-update ()
  (interactive)
  (with-local-quit
    (undo-boundary)
    (save-selected-window
      (dashbuffer-write-content (get-buffer dashbuffer-name))
      (set-buffer-modified-p nil)
      (dashbuffer-cancel-timer)
      (setq dashbuffer-timer (run-at-time dashbuffer-update-interval nil 'dashbuffer-update))
      )))

(defun dashbuffer-create ()
  (setq dashbuffer-itself (pop-to-buffer dashbuffer-name))
  (view-buffer dashbuffer-itself)
  (buffer-disable-undo dashbuffer-itself)
  (shrink-window-if-larger-than-buffer (get-buffer-window dashbuffer-itself))
  (set-window-dedicated-p (get-buffer-window dashbuffer-itself) t)
  (dashbuffer-update))

(defun kill-dashbuffer ()
  (interactive)
  (dashbuffer-cancel-timer)
  (kill-buffer dashbuffer-name)
  (setq dashbuffer-itself nil)
  (setq dashbuffer-timer nil))

(defun bury-dashbuffer ()
  (interactive)
  (quit-window nil (get-buffer-window dashbuffer-itself))
  (bury-buffer dashbuffer-itself))

(defun dashbuffer-cancel-timer ()
  (if dashbuffer-timer
      (cancel-timer dashbuffer-timer)))

(defun dashbuffer-write-content (buf)
  ;;(require 'calendar)
  (require 'solar)

  (set-buffer buf)
  (setq buffer-read-only nil)
  (erase-buffer)
  (progn
    (princ (format-time-string "As of %D at %T:\n") ;time and date
           buf)
    (princ (format
            "%s\n" (solar-sunrise-sunset-string (calendar-current-date))) ;sun data
           buf)
    (princ (format
            "System uptime: %s" (shell-command-to-string "uptime")) ;system uptime
           buf)
    (princ (format
            "Emacs (server) has been running for %s\n" (emacs-uptime)) ;emacs server uptime
           buf)
    (princ (format
            "There are %d open buffers\n" (length (buffer-list))) ;buffer count
           buf)
    (princ (format "Your lucky number for the next %d seconds is %d\n" dashbuffer-update-interval (random))
           buf))
  (setq buffer-read-only t))
