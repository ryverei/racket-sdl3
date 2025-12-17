#lang racket/base

;; Idiomatic dialog boxes - message boxes and confirmations

(require ffi/unsafe
         "../raw.rkt")

(provide
 ;; Simple message boxes
 show-message-box

 ;; Confirmation dialogs
 show-confirm-dialog)

;; ============================================================================
;; Simple Message Boxes
;; ============================================================================

;; show-message-box: Display a simple message box
;; title: the dialog title
;; message: the message text
;; #:type: 'info, 'warning, or 'error (default: 'info)
;; #:window: optional parent window (raw pointer or #f)
;; Returns: #t on success, #f on failure
(define (show-message-box title message
                          #:type [type 'info]
                          #:window [window #f])
  (define flags
    (case type
      [(info information) SDL_MESSAGEBOX_INFORMATION]
      [(warning warn) SDL_MESSAGEBOX_WARNING]
      [(error err) SDL_MESSAGEBOX_ERROR]
      [else (error 'show-message-box
                   "invalid type: ~a (expected 'info, 'warning, or 'error)"
                   type)]))
  (SDL-ShowSimpleMessageBox flags title message window))

;; ============================================================================
;; Confirmation Dialogs
;; ============================================================================

;; show-confirm-dialog: Display a confirmation dialog with custom buttons
;; title: the dialog title
;; message: the message text
;; #:buttons: button configuration - one of:
;;   'yes-no         -> Yes/No buttons, returns 'yes or 'no
;;   'yes-no-cancel  -> Yes/No/Cancel buttons, returns 'yes, 'no, or 'cancel
;;   'ok-cancel      -> OK/Cancel buttons, returns 'ok or 'cancel
;;   'ok             -> Single OK button, returns 'ok
;; #:type: 'info, 'warning, or 'error (default: 'info)
;; #:window: optional parent window (raw pointer or #f)
;; Returns: symbol indicating which button was clicked, or #f on failure
(define (show-confirm-dialog title message
                             #:buttons [buttons 'yes-no]
                             #:type [type 'info]
                             #:window [window #f])
  (define flags
    (case type
      [(info information) SDL_MESSAGEBOX_INFORMATION]
      [(warning warn) SDL_MESSAGEBOX_WARNING]
      [(error err) SDL_MESSAGEBOX_ERROR]
      [else (error 'show-confirm-dialog
                   "invalid type: ~a (expected 'info, 'warning, or 'error)"
                   type)]))

  ;; Define button configurations
  ;; Each config is: (list of (id . label) pairs, return-key-id, escape-key-id)
  (define-values (button-specs return-id escape-id)
    (case buttons
      [(yes-no)
       (values '((0 . "No") (1 . "Yes")) 1 0)]
      [(yes-no-cancel)
       (values '((0 . "Cancel") (1 . "No") (2 . "Yes")) 2 0)]
      [(ok-cancel)
       (values '((0 . "Cancel") (1 . "OK")) 1 0)]
      [(ok)
       (values '((0 . "OK")) 0 0)]
      [else
       (error 'show-confirm-dialog
              "invalid buttons: ~a (expected 'yes-no, 'yes-no-cancel, 'ok-cancel, or 'ok)"
              buttons)]))

  ;; Create button array
  (define num-buttons (length button-specs))
  (define buttons-array
    (cast (malloc (* num-buttons (ctype-sizeof _SDL_MessageBoxButtonData)) 'atomic)
          _pointer _SDL_MessageBoxButtonData-pointer))

  ;; Fill in button data
  (for ([spec (in-list button-specs)]
        [i (in-naturals)])
    (define id (car spec))
    (define label (cdr spec))
    (define btn-flags
      (bitwise-ior
       (if (= id return-id) SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT 0)
       (if (= id escape-id) SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT 0)))
    (ptr-set! buttons-array _SDL_MessageBoxButtonData i
              (make-SDL_MessageBoxButtonData btn-flags id label)))

  ;; Create message box data
  (define msgbox-data
    (make-SDL_MessageBoxData
     flags
     window
     title
     message
     num-buttons
     buttons-array
     #f))  ; no custom color scheme

  ;; Show dialog and get result
  (define-values (success button-id)
    (SDL-ShowMessageBox msgbox-data))

  ;; Convert button ID to symbol
  (if success
      (case buttons
        [(yes-no)
         (case button-id [(0) 'no] [(1) 'yes] [else #f])]
        [(yes-no-cancel)
         (case button-id [(0) 'cancel] [(1) 'no] [(2) 'yes] [else #f])]
        [(ok-cancel)
         (case button-id [(0) 'cancel] [(1) 'ok] [else #f])]
        [(ok)
         (case button-id [(0) 'ok] [else #f])]
        [else #f])
      #f))
