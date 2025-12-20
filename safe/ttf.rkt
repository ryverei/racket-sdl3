#lang racket/base

;; Idiomatic SDL_ttf helpers with custodian-based cleanup

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw.rkt"
         "../raw/ttf.rkt"
         "../private/constants.rkt"
         "texture.rkt"
         "window.rkt"
         "draw.rkt"
         "../private/safe-syntax.rkt")

(provide
 ;; Font management
 open-font
 close-font!
 font?
 font-ptr
 font-destroy!
 copy-font
 add-fallback-font!
 remove-fallback-font!
 clear-fallback-fonts!

 ;; Font properties - getters
 font-size
 font-height
 font-ascent
 font-descent
 font-style
 font-outline
 font-hinting
 font-sdf?
 font-line-skip
 font-kerning?
 font-weight
 font-family-name
 font-style-name
 font-fixed-width?
 font-scalable?
 font-wrap-alignment
 font-direction

 ;; Font properties - setters
 set-font-style!
 set-font-outline!
 set-font-hinting!
 set-font-sdf!
 set-font-size!
 set-font-line-skip!
 set-font-kerning!
 set-font-wrap-alignment!
 set-font-direction!

 ;; Text measurement
 text-size
 text-size-wrapped
 measure-text

 ;; Glyph operations
 font-has-glyph?
 glyph-metrics
 glyph-kerning

 ;; Rendering
 render-text
 draw-text!

 ;; Version info
 ttf-version
 freetype-version
 harfbuzz-version)

;; ==========================================================================
;; Font wrapper struct
;; ==========================================================================

(define-sdl-resource font TTF-CloseFont)

;; ==========================================================================
;; Initialization
;; ==========================================================================

;; NOTE: TTF initialization uses module-level mutable state.
;; SDL_ttf (like SDL itself) is not thread-safe and should only be
;; called from the main thread. If you need to use fonts from multiple
;; threads, render all text on the main thread.

(define ttf-initialized? #f)
(define ttf-shutdown-registered? #f)
(define ttf-shutdown-token (vector 'sdl3-ttf-shutdown))

(define (ensure-ttf-initialized! #:custodian [cust (current-custodian)])
  (unless ttf-initialized?
    (unless (TTF-Init)
      (error 'open-font "Failed to initialize SDL_ttf: ~a" (SDL-GetError)))
    (set! ttf-initialized? #t)

    ;; Tear down SDL_ttf when the custodian shuts down
    (unless ttf-shutdown-registered?
      (register-custodian-shutdown
       ttf-shutdown-token
       (λ (_)
         (when ttf-initialized?
           (TTF-Quit)
           (set! ttf-initialized? #f)))
       cust
       #:at-exit? #t)
      (set! ttf-shutdown-registered? #t))))

;; ==========================================================================
;; Font Management
;; ==========================================================================

(define (open-font path size
                   #:custodian [cust (current-custodian)])
  (ensure-ttf-initialized! #:custodian cust)

  (define ptr (TTF-OpenFont path (exact->inexact size)))
  (unless ptr
    (error 'open-font "Failed to load font ~a: ~a" path (SDL-GetError)))
  (wrap-font ptr #:custodian cust))

;; Alias for consistency with other modules
(define close-font! font-destroy!)

;; ==========================================================================
;; Rendering
;; ==========================================================================

(define (render-text f text color
                     #:renderer [rend #f]
                     #:mode [mode 'blended]
                     #:custodian [cust (current-custodian)])
  (unless rend
    (error 'render-text "renderer is required"))

  (when (font-destroyed? f)
    (error 'render-text "font is closed"))

  (if (string=? text "")
      #f
      (let ()
        (define sdl-color (color->SDL_Color color))

        ;; Render text to a surface using the selected quality mode
        (define surface
          (case mode
            [(solid) (TTF-RenderText-Solid (font-ptr f) text 0 sdl-color)]
            [(blended) (TTF-RenderText-Blended (font-ptr f) text 0 sdl-color)]
            [else (error 'render-text "unsupported mode: ~a" mode)]))

        (unless surface
          (error 'render-text "Failed to render text: ~a" (SDL-GetError)))

        ;; Check surface dimensions - textures are limited to 16384x16384
        (define w (SDL_Surface-w surface))
        (define h (SDL_Surface-h surface))
        (define max-size 16384)

        (cond
          [(or (> w max-size) (> h max-size))
           ;; Text too large for a texture - clean up and return #f
           (SDL-DestroySurface surface)
           #f]
          [else
           ;; Convert to a texture for rendering
           (define tex-ptr (SDL-CreateTextureFromSurface (renderer-ptr rend) surface))
           (SDL-DestroySurface surface)

           (unless tex-ptr
             (error 'render-text "Failed to create texture from text: ~a" (SDL-GetError)))

           (texture-from-pointer tex-ptr #:custodian cust)]))))

(define (draw-text! rend f text x y color
                    #:mode [mode 'blended]
                    #:custodian [cust (current-custodian)])
  (define tex (render-text f text color
                           #:renderer rend
                           #:mode mode
                           #:custodian cust))

  ;; Skip empty text
  (when tex
    (render-texture! rend tex x y)
    (texture-destroy! tex)))

;; ==========================================================================
;; Font Copy and Fallback Fonts
;; ==========================================================================

(define (copy-font f #:custodian [cust (current-custodian)])
  (when (font-destroyed? f)
    (error 'copy-font "font is closed"))
  (define ptr (TTF-CopyFont (font-ptr f)))
  (unless ptr
    (error 'copy-font "Failed to copy font: ~a" (SDL-GetError)))
  (wrap-font ptr #:custodian cust))

(define (add-fallback-font! f fallback)
  (when (font-destroyed? f)
    (error 'add-fallback-font! "primary font is closed"))
  (when (font-destroyed? fallback)
    (error 'add-fallback-font! "fallback font is closed"))
  (unless (TTF-AddFallbackFont (font-ptr f) (font-ptr fallback))
    (error 'add-fallback-font! "Failed to add fallback font: ~a" (SDL-GetError))))

(define (remove-fallback-font! f fallback)
  (when (font-destroyed? f)
    (error 'remove-fallback-font! "primary font is closed"))
  (when (font-destroyed? fallback)
    (error 'remove-fallback-font! "fallback font is closed"))
  (TTF-RemoveFallbackFont (font-ptr f) (font-ptr fallback)))

(define (clear-fallback-fonts! f)
  (when (font-destroyed? f)
    (error 'clear-fallback-fonts! "font is closed"))
  (TTF-ClearFallbackFonts (font-ptr f)))

;; ==========================================================================
;; Font Property Getters
;; ==========================================================================

(define (font-size f)
  (when (font-destroyed? f)
    (error 'font-size "font is closed"))
  (TTF-GetFontSize (font-ptr f)))

(define (font-height f)
  (when (font-destroyed? f)
    (error 'font-height "font is closed"))
  (TTF-GetFontHeight (font-ptr f)))

(define (font-ascent f)
  (when (font-destroyed? f)
    (error 'font-ascent "font is closed"))
  (TTF-GetFontAscent (font-ptr f)))

(define (font-descent f)
  (when (font-destroyed? f)
    (error 'font-descent "font is closed"))
  (TTF-GetFontDescent (font-ptr f)))

(define (font-style f)
  (when (font-destroyed? f)
    (error 'font-style "font is closed"))
  (define style (TTF-GetFontStyle (font-ptr f)))
  (style-flags->symbols style))

(define (font-outline f)
  (when (font-destroyed? f)
    (error 'font-outline "font is closed"))
  (TTF-GetFontOutline (font-ptr f)))

(define (font-hinting f)
  (when (font-destroyed? f)
    (error 'font-hinting "font is closed"))
  (hinting-int->symbol (TTF-GetFontHinting (font-ptr f))))

(define (font-sdf? f)
  (when (font-destroyed? f)
    (error 'font-sdf? "font is closed"))
  (TTF-GetFontSDF (font-ptr f)))

(define (font-line-skip f)
  (when (font-destroyed? f)
    (error 'font-line-skip "font is closed"))
  (TTF-GetFontLineSkip (font-ptr f)))

(define (font-kerning? f)
  (when (font-destroyed? f)
    (error 'font-kerning? "font is closed"))
  (TTF-GetFontKerning (font-ptr f)))

(define (font-weight f)
  (when (font-destroyed? f)
    (error 'font-weight "font is closed"))
  (TTF-GetFontWeight (font-ptr f)))

(define (font-family-name f)
  (when (font-destroyed? f)
    (error 'font-family-name "font is closed"))
  (TTF-GetFontFamilyName (font-ptr f)))

(define (font-style-name f)
  (when (font-destroyed? f)
    (error 'font-style-name "font is closed"))
  (TTF-GetFontStyleName (font-ptr f)))

(define (font-fixed-width? f)
  (when (font-destroyed? f)
    (error 'font-fixed-width? "font is closed"))
  (TTF-FontIsFixedWidth (font-ptr f)))

(define (font-scalable? f)
  (when (font-destroyed? f)
    (error 'font-scalable? "font is closed"))
  (TTF-FontIsScalable (font-ptr f)))

(define (font-wrap-alignment f)
  (when (font-destroyed? f)
    (error 'font-wrap-alignment "font is closed"))
  (alignment-int->symbol (TTF-GetFontWrapAlignment (font-ptr f))))

(define (font-direction f)
  (when (font-destroyed? f)
    (error 'font-direction "font is closed"))
  (direction-int->symbol (TTF-GetFontDirection (font-ptr f))))

;; ==========================================================================
;; Font Property Setters
;; ==========================================================================

(define (set-font-style! f . styles)
  (when (font-destroyed? f)
    (error 'set-font-style! "font is closed"))
  (define style-flags (symbols->style-flags styles))
  (TTF-SetFontStyle (font-ptr f) style-flags))

(define (set-font-outline! f pixels)
  (when (font-destroyed? f)
    (error 'set-font-outline! "font is closed"))
  (unless (TTF-SetFontOutline (font-ptr f) pixels)
    (error 'set-font-outline! "Failed to set outline: ~a" (SDL-GetError))))

(define (set-font-hinting! f mode)
  (when (font-destroyed? f)
    (error 'set-font-hinting! "font is closed"))
  (TTF-SetFontHinting (font-ptr f) (symbol->hinting-int mode)))

(define (set-font-sdf! f enabled?)
  (when (font-destroyed? f)
    (error 'set-font-sdf! "font is closed"))
  (unless (TTF-SetFontSDF (font-ptr f) enabled?)
    (error 'set-font-sdf! "Failed to set SDF mode: ~a" (SDL-GetError))))

(define (set-font-size! f size #:hdpi [hdpi #f] #:vdpi [vdpi #f])
  (when (font-destroyed? f)
    (error 'set-font-size! "font is closed"))
  (define result
    (if (and hdpi vdpi)
        (TTF-SetFontSizeDPI (font-ptr f) (exact->inexact size) hdpi vdpi)
        (TTF-SetFontSize (font-ptr f) (exact->inexact size))))
  (unless result
    (error 'set-font-size! "Failed to set font size: ~a" (SDL-GetError))))

(define (set-font-line-skip! f skip)
  (when (font-destroyed? f)
    (error 'set-font-line-skip! "font is closed"))
  (TTF-SetFontLineSkip (font-ptr f) skip))

(define (set-font-kerning! f enabled?)
  (when (font-destroyed? f)
    (error 'set-font-kerning! "font is closed"))
  (TTF-SetFontKerning (font-ptr f) enabled?))

(define (set-font-wrap-alignment! f alignment)
  (when (font-destroyed? f)
    (error 'set-font-wrap-alignment! "font is closed"))
  (TTF-SetFontWrapAlignment (font-ptr f) (symbol->alignment-int alignment)))

(define (set-font-direction! f direction)
  (when (font-destroyed? f)
    (error 'set-font-direction! "font is closed"))
  (unless (TTF-SetFontDirection (font-ptr f) (symbol->direction-int direction))
    (error 'set-font-direction! "Failed to set direction (HarfBuzz may not be available)")))

;; ==========================================================================
;; Text Measurement
;; ==========================================================================

(define (text-size f text)
  (when (font-destroyed? f)
    (error 'text-size "font is closed"))
  (define w-ptr (malloc _int))
  (define h-ptr (malloc _int))
  (unless (TTF-GetStringSize (font-ptr f) text 0 w-ptr h-ptr)
    (error 'text-size "Failed to measure text: ~a" (SDL-GetError)))
  (values (ptr-ref w-ptr _int) (ptr-ref h-ptr _int)))

(define (text-size-wrapped f text wrap-width)
  (when (font-destroyed? f)
    (error 'text-size-wrapped "font is closed"))
  (define w-ptr (malloc _int))
  (define h-ptr (malloc _int))
  (unless (TTF-GetStringSizeWrapped (font-ptr f) text 0 wrap-width w-ptr h-ptr)
    (error 'text-size-wrapped "Failed to measure wrapped text: ~a" (SDL-GetError)))
  (values (ptr-ref w-ptr _int) (ptr-ref h-ptr _int)))

(define (measure-text f text max-width)
  (when (font-destroyed? f)
    (error 'measure-text "font is closed"))
  (define width-ptr (malloc _int))
  (define length-ptr (malloc _size))
  (unless (TTF-MeasureString (font-ptr f) text 0 max-width width-ptr length-ptr)
    (error 'measure-text "Failed to measure text: ~a" (SDL-GetError)))
  (values (ptr-ref width-ptr _int) (ptr-ref length-ptr _size)))

;; ==========================================================================
;; Glyph Operations
;; ==========================================================================

(define (font-has-glyph? f ch)
  (when (font-destroyed? f)
    (error 'font-has-glyph? "font is closed"))
  (define codepoint (if (char? ch) (char->integer ch) ch))
  (TTF-FontHasGlyph (font-ptr f) codepoint))

(define (glyph-metrics f ch)
  (when (font-destroyed? f)
    (error 'glyph-metrics "font is closed"))
  (define codepoint (if (char? ch) (char->integer ch) ch))
  (define minx-ptr (malloc _int))
  (define maxx-ptr (malloc _int))
  (define miny-ptr (malloc _int))
  (define maxy-ptr (malloc _int))
  (define advance-ptr (malloc _int))
  (unless (TTF-GetGlyphMetrics (font-ptr f) codepoint
                                minx-ptr maxx-ptr miny-ptr maxy-ptr advance-ptr)
    (error 'glyph-metrics "Failed to get glyph metrics: ~a" (SDL-GetError)))
  (values (ptr-ref minx-ptr _int)
          (ptr-ref maxx-ptr _int)
          (ptr-ref miny-ptr _int)
          (ptr-ref maxy-ptr _int)
          (ptr-ref advance-ptr _int)))

(define (glyph-kerning f prev-ch ch)
  (when (font-destroyed? f)
    (error 'glyph-kerning "font is closed"))
  (define prev-codepoint (if (char? prev-ch) (char->integer prev-ch) prev-ch))
  (define codepoint (if (char? ch) (char->integer ch) ch))
  (define kerning-ptr (malloc _int))
  (unless (TTF-GetGlyphKerning (font-ptr f) prev-codepoint codepoint kerning-ptr)
    (error 'glyph-kerning "Failed to get glyph kerning: ~a" (SDL-GetError)))
  (ptr-ref kerning-ptr _int))

;; ==========================================================================
;; Version Information
;; ==========================================================================

(define (ttf-version)
  (define packed (TTF-Version))
  ;; SDL_VERSIONNUM format: major * 1000000 + minor * 1000 + patch
  (values (quotient packed 1000000)
          (quotient (remainder packed 1000000) 1000)
          (remainder packed 1000)))

(define (freetype-version)
  (define major-ptr (malloc _int))
  (define minor-ptr (malloc _int))
  (define patch-ptr (malloc _int))
  (TTF-GetFreeTypeVersion major-ptr minor-ptr patch-ptr)
  (values (ptr-ref major-ptr _int)
          (ptr-ref minor-ptr _int)
          (ptr-ref patch-ptr _int)))

(define (harfbuzz-version)
  (define major-ptr (malloc _int))
  (define minor-ptr (malloc _int))
  (define patch-ptr (malloc _int))
  (TTF-GetHarfBuzzVersion major-ptr minor-ptr patch-ptr)
  (define major (ptr-ref major-ptr _int))
  (define minor (ptr-ref minor-ptr _int))
  (define patch (ptr-ref patch-ptr _int))
  ;; Returns (values #f #f #f) if HarfBuzz is not available (all zeros)
  ;; Otherwise returns (values major minor patch)
  (if (and (= major 0) (= minor 0) (= patch 0))
      (values #f #f #f)
      (values major minor patch)))

;; ==========================================================================
;; Helper Functions for Enum Conversion
;; ==========================================================================

;; Style flags <-> symbols
(define (style-flags->symbols flags)
  (if (= flags TTF_STYLE_NORMAL)
      '(normal)
      (filter
       values
       (list (and (not (zero? (bitwise-and flags TTF_STYLE_BOLD))) 'bold)
             (and (not (zero? (bitwise-and flags TTF_STYLE_ITALIC))) 'italic)
             (and (not (zero? (bitwise-and flags TTF_STYLE_UNDERLINE))) 'underline)
             (and (not (zero? (bitwise-and flags TTF_STYLE_STRIKETHROUGH))) 'strikethrough)))))

(define (symbols->style-flags styles)
  (if (or (null? styles) (equal? styles '(normal)))
      TTF_STYLE_NORMAL
      (apply bitwise-ior
             (map (lambda (s)
                    (case s
                      [(normal) TTF_STYLE_NORMAL]
                      [(bold) TTF_STYLE_BOLD]
                      [(italic) TTF_STYLE_ITALIC]
                      [(underline) TTF_STYLE_UNDERLINE]
                      [(strikethrough) TTF_STYLE_STRIKETHROUGH]
                      [else (error 'set-font-style! "unknown style: ~a" s)]))
                  styles))))

;; Hinting mode <-> symbol
(define (hinting-int->symbol h)
  (cond
    [(= h TTF_HINTING_NORMAL) 'normal]
    [(= h TTF_HINTING_LIGHT) 'light]
    [(= h TTF_HINTING_MONO) 'mono]
    [(= h TTF_HINTING_NONE) 'none]
    [(= h TTF_HINTING_LIGHT_SUBPIXEL) 'light-subpixel]
    [else 'invalid]))

(define (symbol->hinting-int s)
  (case s
    [(normal) TTF_HINTING_NORMAL]
    [(light) TTF_HINTING_LIGHT]
    [(mono) TTF_HINTING_MONO]
    [(none) TTF_HINTING_NONE]
    [(light-subpixel) TTF_HINTING_LIGHT_SUBPIXEL]
    [else (error 'set-font-hinting! "unknown hinting mode: ~a" s)]))

;; Alignment <-> symbol
(define (alignment-int->symbol a)
  (cond
    [(= a TTF_HORIZONTAL_ALIGN_LEFT) 'left]
    [(= a TTF_HORIZONTAL_ALIGN_CENTER) 'center]
    [(= a TTF_HORIZONTAL_ALIGN_RIGHT) 'right]
    [else 'invalid]))

(define (symbol->alignment-int s)
  (case s
    [(left) TTF_HORIZONTAL_ALIGN_LEFT]
    [(center) TTF_HORIZONTAL_ALIGN_CENTER]
    [(right) TTF_HORIZONTAL_ALIGN_RIGHT]
    [else (error 'set-font-wrap-alignment! "unknown alignment: ~a" s)]))

;; Direction <-> symbol
(define (direction-int->symbol d)
  (cond
    [(= d TTF_DIRECTION_LTR) 'ltr]
    [(= d TTF_DIRECTION_RTL) 'rtl]
    [(= d TTF_DIRECTION_TTB) 'ttb]
    [(= d TTF_DIRECTION_BTT) 'btt]
    [else 'invalid]))

(define (symbol->direction-int s)
  (case s
    [(ltr) TTF_DIRECTION_LTR]
    [(rtl) TTF_DIRECTION_RTL]
    [(ttb) TTF_DIRECTION_TTB]
    [(btt) TTF_DIRECTION_BTT]
    [else (error 'set-font-direction! "unknown direction: ~a" s)]))
