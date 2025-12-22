#!/usr/bin/env racket
#lang racket/base

;; Checks that documented functions exist in the sdl3 module
;; Run with: PLTCOLLECTS="$PWD:" racket scripts/check-docs.rkt

(require racket/set
         racket/string
         racket/file
         racket/match)

;; Get all exports from sdl3
(define sdl3-exports
  (let ()
    (define ns (make-base-namespace))
    (parameterize ([current-namespace ns])
      (namespace-require 'sdl3)
      (list->set (namespace-mapped-symbols ns)))))

;; Extract documented identifiers from scrbl files
(define (extract-documented-ids file)
  (define content (file->string file))
  ;; Match @defproc[(name ...)] and @defform[(name ...)]
  (define pattern #rx"@def(?:proc|form)\\[\\(([a-zA-Z0-9_?!+<>=-]+)")
  (for/list ([m (in-list (regexp-match* pattern content #:match-select cadr))])
    (string->symbol m)))

;; Find all scrbl files
(define scrbl-files
  (for/list ([f (in-directory "scribblings")]
             #:when (regexp-match? #rx"\\.scrbl$" (path->string f)))
    f))

(printf "Checking documentation against sdl3 exports...~n~n")

(define documented-ids
  (list->set
   (apply append
          (for/list ([f (in-list scrbl-files)])
            (extract-documented-ids f)))))

;; Find documented but not exported
(define doc-not-exported
  (set-subtract documented-ids sdl3-exports))

;; Find exported but not documented (optional - there will be many)
(define exported-not-doc
  (set-subtract sdl3-exports documented-ids))

(unless (set-empty? doc-not-exported)
  (printf "WARNING: Documented but not exported from sdl3:~n")
  (for ([id (in-set doc-not-exported)])
    (printf "  ~a~n" id))
  (newline))

(printf "Documented functions: ~a~n" (set-count documented-ids))
(printf "Exported from sdl3: ~a~n" (set-count sdl3-exports))
(printf "Undocumented exports: ~a~n" (set-count exported-not-doc))

(when (set-empty? doc-not-exported)
  (printf "~nAll documented functions exist in sdl3 exports.~n"))
