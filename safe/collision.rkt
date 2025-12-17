#lang racket/base

;; Safe rectangle collision detection API

(require "../raw.rkt"
         "../private/types.rkt")

(provide
 ;; Rectangle creation and accessors
 make-rect
 rect-x
 rect-y
 rect-w
 rect-h

 ;; Collision detection
 rects-intersect?
 rect-intersection)

;; ============================================================================
;; Rectangle creation and accessors
;; ============================================================================

;; Create a rectangle (x y w h)
;; Returns an opaque rect object
(define (make-rect x y w h)
  (make-SDL_Rect (inexact->exact (truncate x))
                 (inexact->exact (truncate y))
                 (inexact->exact (truncate w))
                 (inexact->exact (truncate h))))

;; Accessors for rect components
(define (rect-x r) (SDL_Rect-x r))
(define (rect-y r) (SDL_Rect-y r))
(define (rect-w r) (SDL_Rect-w r))
(define (rect-h r) (SDL_Rect-h r))

;; ============================================================================
;; Collision detection
;; ============================================================================

;; Check if two rectangles intersect
;; Returns #t if they overlap, #f otherwise
(define (rects-intersect? a b)
  (SDL-HasRectIntersection a b))

;; Get the intersection of two rectangles
;; Returns a rect representing the overlap, or #f if they don't intersect
(define (rect-intersection a b)
  (if (SDL-HasRectIntersection a b)
      (let ([result (make-SDL_Rect 0 0 0 0)])
        (SDL-GetRectIntersection a b result)
        result)
      #f))
