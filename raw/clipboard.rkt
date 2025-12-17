#lang racket/base

;; SDL3 Clipboard Access
;;
;; Functions for reading and writing clipboard text.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-SetClipboardText
         SDL-GetClipboardText
         SDL-HasClipboardText)

;; ============================================================================
;; Clipboard
;; ============================================================================

;; SDL_SetClipboardText: Put UTF-8 text into the clipboard
;; text: the text to store in the clipboard
;; Returns: true on success, false on failure
(define-sdl SDL-SetClipboardText
  (_fun _string/utf-8 -> _sdl-bool)
  #:c-id SDL_SetClipboardText)

;; SDL_GetClipboardText: Get UTF-8 text from the clipboard
;; Returns: pointer to clipboard text (must be freed with SDL_free)
;; Note: Returns empty string if clipboard is empty or on error
(define-sdl SDL-GetClipboardText
  (_fun -> _pointer)
  #:c-id SDL_GetClipboardText)

;; SDL_HasClipboardText: Query whether the clipboard has text
;; Returns: true if the clipboard has text, false otherwise
(define-sdl SDL-HasClipboardText
  (_fun -> _stdbool)
  #:c-id SDL_HasClipboardText)
