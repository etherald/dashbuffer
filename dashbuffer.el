;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dashbuffer.el
;;; run elisp to create an informational buffer in your emacs

;;; to use, say like:
;;; (load "~/elisp/dashbuffer.el")
;;; (add-hook 'before-make-frame-hook 'dashbuffer)

;;; TODO: rationalize update options
;;; TODO: pass function from init file
;;; TODO: should callback return a string?
;;; TODO: plugin type output modules
;;; TODO: logging? append to buffer
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; if auto update true and when-idle true repeate update after idle
;;; timeout
;;; if auto update false andwhen-idle true update once after timeout
;;; if auto update true and when-idle false update always after interval
;;; if both false show info once, never update


(defcustom dashbuffer-name "*Dashboard*"
  "Name for the dashbuffer buffer."
  :group 'dashbuffer
  :type 'string)

(defcustom dashbuffer-update-interval 30
  "Interval in seconds between dashbuffer updates."
  :group 'dashbuffer
  :type 'integer)

(defcustom dashbuffer-idle-interval 3
  "Interval in seconds for idle wait."
  :group 'dashbuffer
  :type 'integer)

(defcustom dashbuffer-auto-update t
  "Whether the dashbuffer should update on a timer."
  :group 'dashbuffer
  :type 'boolean)

(defcustom dashbuffer-start-when-idle nil
  "Whether to update the buffer only after Emacs has been idle for the specified time.
Defaults to true. Otherwise the buffer will update after dashbuffer-update-interval has elapsed."
  :group 'dashbuffer
  :type 'boolean)

;;; cache
(defvar dashbuffer-timer nil)
(defvar dashbuffer-itself nil)

(defun dashbuffer ()
  (interactive)
  (add-hook 'kill-buffer-hook 'dashbuffer-cleanup)
  (if (buffer-live-p  dashbuffer-itself)
      (pop-to-buffer dashbuffer-name nil t)
    (dashbuffer-create))
  (if dashbuffer-start-when-idle
      (run-with-idle-timer dashbuffer-idle-interval t 'dashbuffer-update)))

(defun dashbuffer-update ()
  (interactive)
  (with-local-quit
    ;;(undo-boundary)
    (save-selected-window
      (dashbuffer-write-content dashbuffer-itself)
      (set-buffer-modified-p nil)
      (if dashbuffer-auto-update
          (dashbuffer-reset-timer)))))

(defun dashbuffer-create ()
  (setq dashbuffer-itself (pop-to-buffer dashbuffer-name))
  (view-buffer dashbuffer-itself)
  (buffer-disable-undo dashbuffer-itself)
  (set-window-dedicated-p (get-buffer-window dashbuffer-itself) t)
  (dashbuffer-update)
  (fit-window-to-buffer (get-buffer-window dashbuffer-itself))
  (shrink-window-if-larger-than-buffer (get-buffer-window dashbuffer-itself))
  )

(defun dashbuffer-kill-buffer ()
  (kill-buffer dashbuffer-name))

(defun dashbuffer-cleanup ()
  (dashbuffer-cancel-timer)
  (setq dashbuffer-itself nil)
  (setq dashbuffer-timer nil))

(defun kill-dashbuffer ()
  (interactive)
  (dashbuffer-kill-buffer))

(defun bury-dashbuffer ()
  (interactive)
  (quit-window nil (get-buffer-window dashbuffer-itself))
  (bury-buffer dashbuffer-itself))

(defun dashbuffer-reset-timer ()
  (dashbuffer-cancel-timer)
  (setq dashbuffer-timer
        (run-at-time dashbuffer-update-interval nil 'dashbuffer-update)))

(defun dashbuffer-cancel-timer ()
  (if dashbuffer-timer
      (progn
        (cancel-timer dashbuffer-timer)
        (setq dashbuffer-timer nil))))

(defun dashbuffer-write-line (str)
  (interactive "s")
  (set-buffer dashbuffer-itself)
  (setq buffer-read-only nil)
  ;;(princ (format "%s\n" str) dashbuffer-itself)
  (princ str dashbuffer-itself)
  (setq buffer-modified-p nil)
  (setq buffer-read-only t))

(defun dashbuffer-write-content (buf)
  ;;(require 'calendar)
  (require 'solar)
  ;;(set-buffer buf)
  (set-buffer dashbuffer-itself)
  ;;(setq buffer-read-only nil)
  (erase-buffer)
  (progn
    (dashbuffer-write-line
     (format-time-string "As of %D at %T:\n"))
    (dashbuffer-write-line
     (format "%s\n" (solar-sunrise-sunset-string (calendar-current-date))))
    (dashbuffer-write-line
     (format "System uptime: %s" (shell-command-to-string "uptime")))
    (dashbuffer-write-line
     (format "Emacs (server) has been running for %s\n" (emacs-uptime)))
    (dashbuffer-write-line
     (format "There are %d open buffers\n" (length (buffer-list))))
    (if dashbuffer-auto-update
        (dashbuffer-write-line
         (format "Your lucky number for the next %d seconds is %d\n" dashbuffer-update-interval (random))))
    )

                                        ;(setq buffer-read-only t)
  )
