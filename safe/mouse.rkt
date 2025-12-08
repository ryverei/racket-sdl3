#lang racket/base

;; Idiomatic mouse helpers

(require ffi/unsafe
         "../raw.rkt")

(provide
 get-mouse-state
 mouse-button-pressed?)

;; =========================================================================
;; State
;; =========================================================================

(define (get-mouse-state)
  (define x-ptr (malloc _float 'atomic-interior))
  (define y-ptr (malloc _float 'atomic-interior))
  (define mask (SDL-GetMouseState x-ptr y-ptr))
  (values (ptr-ref x-ptr _float)
          (ptr-ref y-ptr _float)
          mask))

(define (mouse-button-pressed? mask button)
  (not (zero? (bitwise-and mask button))))
