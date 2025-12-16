# Code Review: racket-sdl3

This document identifies opportunities for improving the architecture and code quality of the racket-sdl3 library.

## Executive Summary

The project has a solid foundation with clear separation between raw FFI bindings and safe wrappers. The main improvement opportunities are in reducing code duplication through macros and shared utilities. Estimated ~100-150 lines of repetitive code could be eliminated.

---

## 1. Resource Wrapper Pattern Duplication

**Problem**: The same struct-with-destructor pattern is repeated in `safe/window.rkt`, `safe/texture.rkt`, and `safe/ttf.rkt`.

**Current Pattern** (repeated 3 times):

```racket
;; In safe/window.rkt
(struct window (ptr [destroyed? #:mutable])
  #:property prop:cpointer (λ (w) (window-ptr w)))

(define (make-window! ...)
  (define ptr (SDL-CreateWindow ...))
  (unless ptr (error ...))
  (define win (window ptr #f))
  (register-custodian-shutdown
   win
   (λ (w)
     (unless (window-destroyed? w)
       (SDL-DestroyWindow (window-ptr w))
       (set-window-destroyed?! w #t)))
   cust
   #:at-exit? #t)
  win)

;; In safe/texture.rkt - nearly identical
(struct texture (ptr [destroyed? #:mutable])
  #:property prop:cpointer (λ (t) (texture-ptr t)))
;; ... same registration pattern ...

;; In safe/ttf.rkt - nearly identical
(struct font (ptr [destroyed? #:mutable])
  #:property prop:cpointer (λ (f) (font-ptr f)))
;; ... same registration pattern ...
```

**Proposed Solution**: Create a macro in `safe/syntax.rkt`:

```racket
(define-syntax-rule (define-sdl-resource name destructor)
  (begin
    (struct name (ptr [destroyed? #:mutable])
      #:property prop:cpointer (λ (obj) (name-ptr obj)))

    (define (name-destroy! obj)
      (unless (name-destroyed? obj)
        (destructor (name-ptr obj))
        (set-name-destroyed?! obj #t)))

    (define (wrap-name ptr #:custodian [cust (current-custodian)])
      (define obj (name ptr #f))
      (register-custodian-shutdown obj name-destroy! cust #:at-exit? #t)
      obj)))

;; Usage:
(define-sdl-resource window SDL-DestroyWindow)
(define-sdl-resource texture SDL-DestroyTexture)
(define-sdl-resource font TTF-CloseFont)
```

**Impact**: Eliminates ~60 lines of duplicated code.

---

## 2. Symbol-to-Constant Bidirectional Conversion

**Problem**: Multiple modules implement identical bidirectional conversion patterns.

**Current Pattern** (repeated 5+ times):

```racket
;; In safe/draw.rkt
(define (symbol->blend-mode sym)
  (case sym
    [(none) SDL_BLENDMODE_NONE]
    [(blend alpha) SDL_BLENDMODE_BLEND]
    [(add additive) SDL_BLENDMODE_ADD]
    ;; ... more cases ...
    [else (error 'symbol->blend-mode "Unknown blend mode: ~a" sym)]))

(define (blend-mode->symbol mode)
  (cond
    [(= mode SDL_BLENDMODE_NONE) 'none]
    [(= mode SDL_BLENDMODE_BLEND) 'blend]
    [(= mode SDL_BLENDMODE_ADD) 'add]
    ;; ... more cases ...
    [else 'unknown]))

;; Similar pairs exist for:
;; - system cursors (19 cases)
;; - scale modes (3 cases)
;; - flip modes (4 cases)
;; - texture access modes (3 cases)
```

**Proposed Solution**: Create a macro in `safe/syntax.rkt`:

```racket
(define-syntax (define-enum-conversion stx)
  (syntax-parse stx
    [(_ name:id ([sym:id ... constant:expr] ...))
     #'(begin
         (define (symbol->name sym-arg)
           (case sym-arg
             [(sym ...) constant] ...
             [else (error 'symbol->name "Unknown ~a: ~a" 'name sym-arg)]))
         (define (name->symbol val)
           (cond
             [(= val constant) 'sym] ...  ; Uses first symbol as canonical
             [else 'unknown])))]))

;; Usage:
(define-enum-conversion blend-mode
  ([none]       SDL_BLENDMODE_NONE)
  ([blend alpha] SDL_BLENDMODE_BLEND)
  ([add additive] SDL_BLENDMODE_ADD)
  ([mod]        SDL_BLENDMODE_MOD)
  ([mul]        SDL_BLENDMODE_MUL)
  ([invalid]    SDL_BLENDMODE_INVALID))

(define-enum-conversion scale-mode
  ([nearest] SDL_SCALEMODE_NEAREST)
  ([linear]  SDL_SCALEMODE_LINEAR))
```

**Impact**: Eliminates ~80 lines of duplicated code, ensures consistency.

---

## 3. Library Loading Triplication

**Problem**: The same platform-specific library loading logic appears in three files.

**Current Pattern** (in `private/lib.rkt`, `image.rkt`, `ttf.rkt`):

```racket
(define sdl3-lib-paths
  (case (system-type 'os)
    [(macosx)
     '("/opt/homebrew/lib/libSDL3"
       "/usr/local/lib/libSDL3"
       "libSDL3")]
    [(unix)
     '("libSDL3"
       "/usr/lib/libSDL3"
       "/usr/local/lib/libSDL3")]
    [(windows)
     '("SDL3")]
    [else '("libSDL3")]))

(define sdl3-lib
  (let loop ([paths sdl3-lib-paths])
    (if (null? paths)
        (ffi-lib "libSDL3" '("0" #f))
        (with-handlers ([exn:fail? (λ (e) (loop (cdr paths)))])
          (ffi-lib (car paths) '("0" #f))))))
```

**Proposed Solution**: Extract to a shared function in `private/syntax.rkt`:

```racket
(define (load-sdl-library base-name)
  (define paths
    (case (system-type 'os)
      [(macosx)
       (list (string-append "/opt/homebrew/lib/lib" base-name)
             (string-append "/usr/local/lib/lib" base-name)
             (string-append "lib" base-name))]
      [(unix)
       (list (string-append "lib" base-name)
             (string-append "/usr/lib/lib" base-name)
             (string-append "/usr/local/lib/lib" base-name))]
      [(windows)
       (list base-name)]
      [else
       (list (string-append "lib" base-name))]))
  (let loop ([ps paths])
    (if (null? ps)
        (ffi-lib (string-append "lib" base-name) '("0" #f))
        (with-handlers ([exn:fail? (λ (_) (loop (cdr ps)))])
          (ffi-lib (car ps) '("0" #f))))))

;; Usage:
(define sdl3-lib (load-sdl-library "SDL3"))
(define sdl3-image-lib (load-sdl-library "SDL3_image"))
(define sdl3-ttf-lib (load-sdl-library "SDL3_ttf"))
```

**Impact**: Eliminates ~40 lines of duplicated code.

---

## 4. Color Conversion Not Centralized

**Problem**: Color conversion logic exists in `safe/ttf.rkt` but isn't available to other modules.

**Current Code** (in `safe/ttf.rkt`):

```racket
(define (color-struct? v)
  (with-handlers ([exn:fail? (λ (_) #f)])
    (SDL_Color-r v)
    #t))

(define (color->SDL_Color color)
  (cond
    [(color-struct? color) color]
    [(and (list? color) (>= (length color) 3))
     (make-SDL_Color (list-ref color 0)
                     (list-ref color 1)
                     (list-ref color 2)
                     (if (>= (length color) 4)
                         (list-ref color 3)
                         255))]
    [else (error 'color->SDL_Color "Invalid color: ~a" color)]))
```

**Proposed Solution**: Move to `safe/draw.rkt` and export for use across modules.

---

## 5. Event Loop Boilerplate

**Problem**: Examples repeat the same event loop structure.

**Current Pattern** (in most examples):

```racket
(define still-running?
  (for/fold ([run? #t])
            ([ev (in-events)]
             #:break (not run?))
    (match ev
      [(or (quit-event) (window-event 'close-requested)) #f]
      [(key-event 'down 'escape) #f]
      [_ run?])))
```

**Proposed Solution**: Provide an event loop helper in `safe/events.rkt`:

```racket
;; Simple version - just check for quit
(define (should-quit? ev)
  (match ev
    [(or (quit-event) (window-event 'close-requested)) #t]
    [(key-event 'down 'escape) #t]
    [_ #f]))

;; Or a more flexible macro
(define-syntax-rule (with-event-loop body ...)
  (let loop ()
    (define quit?
      (for/or ([ev (in-events)])
        (cond [(should-quit? ev) #t]
              [else body ... #f])))
    (unless quit? (loop))))
```

---

## 6. Inconsistent Error Handling

**Problem**: Different patterns used for checking SDL function success.

**Pattern A** (using `unless`):
```racket
(define (sdl-init! [flags SDL_INIT_VIDEO])
  (unless (SDL-Init flags)
    (error 'sdl-init! "Failed to initialize SDL: ~a" (SDL-GetError))))
```

**Pattern B** (using `if` with multiple values):
```racket
(define (get-blend-mode rend)
  (define-values (success mode) (SDL-GetRenderDrawBlendMode (renderer-ptr rend)))
  (if success
      (blend-mode->symbol mode)
      (error 'get-blend-mode "failed to get blend mode")))
```

**Proposed Solution**: Create consistent error-checking helpers in `private/syntax.rkt`:

```racket
(define-syntax-rule (check-sdl-success name expr)
  (unless expr
    (error name "~a" (SDL-GetError))))

(define-syntax-rule (check-sdl-result name success-expr result-expr)
  (if success-expr
      result-expr
      (error name "~a" (SDL-GetError))))
```

---

## 7. TTF Singleton State

**Problem**: TTF uses mutable module-level state that's not thread-safe.

**Current Code**:
```racket
(define ttf-initialized? #f)
(define ttf-shutdown-registered? #f)

(define (ensure-ttf-initialized! #:custodian [cust (current-custodian)])
  (unless ttf-initialized?
    (unless (TTF-Init)
      (error 'open-font "Failed to initialize SDL_ttf: ~a" (SDL-GetError)))
    (set! ttf-initialized? #t)
    ;; ... register shutdown ...
    ))
```

**Issues**:
- Race condition if called from multiple threads
- State is implicit and hard to test

**Proposed Solution**: Either:
1. Add a mutex for thread safety
2. Document that TTF functions must be called from a single thread
3. Use a semaphore-protected initialization

---

## 8. Lessons from racket-sdl2

The racket-sdl2 library offers several patterns worth considering:

### Dual API Approach
- `main.rkt`: C-style names (`SDL_Init`, `SDL_CreateWindow`)
- `pretty.rkt`: Scheme-style names (`init!`, `create-window!`)

Our current approach with `raw.rkt` and `safe/` is similar but could benefit from:
- A macro to automatically generate Scheme-style names from C-style names
- More consistent naming transformation rules

### Inline Helpers
racket-sdl2 uses `begin-encourage-inline` for performance-critical helpers:
```racket
(begin-encourage-inline
  (define (SDL_RectEmpty r)
    (or (not r)
        (<= (SDL_Rect-w r) 0)
        (<= (SDL_Rect-h r) 0))))
```

### Enum/Bitmask Types
racket-sdl2 uses `_enum` and `_bitmask` types more extensively:
```racket
(define _audio-status
  (_enum '(stopped = 0 playing paused)))

(define _SDL_Keymod
  (_bitmask '(KMOD_NONE = #x0000
              KMOD_LSHIFT = #x0001
              KMOD_RSHIFT = #x0002)))
```

We could adopt this for cleaner type definitions.

---

## Priority Summary

| Priority | Issue | Estimated Lines Saved |
|----------|-------|----------------------|
| High | Resource wrapper macro | ~60 lines |
| High | Enum conversion macro | ~80 lines |
| High | Library loading helper | ~40 lines |
| Medium | Centralize color conversion | ~20 lines |
| Medium | Event loop helper | N/A (developer convenience) |
| Medium | Error handling consistency | N/A (code quality) |
| Low | TTF thread safety | N/A (correctness) |

---

## Proposed New Files

1. **`private/syntax.rkt`** - Low-level macros for FFI patterns:
   - `load-sdl-library` helper function
   - `check-sdl-success` / `check-sdl-result` error handling macros

2. **`safe/syntax.rkt`** - High-level macros for safe wrappers:
   - `define-sdl-resource` macro (resource wrapper with custodian cleanup)
   - `define-enum-conversion` macro (bidirectional symbol/constant conversion)

---

## Next Steps

1. Create `private/syntax.rkt` with library loading helper and error macros
2. Create `safe/syntax.rkt` with resource wrapper and enum conversion macros
3. Refactor `safe/window.rkt`, `safe/texture.rkt`, `safe/ttf.rkt` to use new macros
4. Consolidate library loading in `image.rkt` and `ttf.rkt` to use `load-sdl-library`
5. Move color conversion to `safe/draw.rkt`
