#lang info

(define collection "sdl3")
(define pkg-name "sdl3")
(define version "0.1")
(define pkg-desc "SDL3 bindings for Racket")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc"))
(define license 'MIT)
(define compile-omit-paths '("examples" "demos" "scripts"))
;; Omit all tests - this is an FFI package that requires SDL3 to be installed,
;; which is not available on the package build server
(define test-omit-paths 'all)
(define scribblings '(("scribblings/sdl3.scrbl" (multi-page))))
(define pkg-authors '("rmckayfleming@gmail.com"))
