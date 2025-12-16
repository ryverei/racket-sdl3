#lang racket/base

;; Idiomatic clipboard helpers

(require ffi/unsafe
         "../raw.rkt")

(provide
 ;; Clipboard operations
 clipboard-text
 set-clipboard-text!
 clipboard-has-text?)

;; =========================================================================
;; Clipboard Operations
;; =========================================================================

;; Get text from the system clipboard
;; Returns: string if clipboard has text, #f otherwise
(define (clipboard-text)
  (if (SDL-HasClipboardText)
      (let ([ptr (SDL-GetClipboardText)])
        (if ptr
            (let ([str (cast ptr _pointer _string/utf-8)])
              (SDL-free ptr)
              (if (and str (not (string=? str "")))
                  str
                  #f))
            #f))
      #f))

;; Set the system clipboard text
;; text: the string to copy to clipboard
;; Returns: #t on success
;; Raises error on failure
(define (set-clipboard-text! text)
  (unless (SDL-SetClipboardText text)
    (error 'set-clipboard-text! "Failed to set clipboard text: ~a" (SDL-GetError)))
  #t)

;; Check if the clipboard has text
;; Returns: #t if clipboard has text, #f otherwise
(define (clipboard-has-text?)
  (SDL-HasClipboardText))
