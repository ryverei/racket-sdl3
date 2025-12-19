#lang racket/base

;; SDL3 Surface Operations
;;
;; Functions for managing surfaces (software-based image buffers).
;; Surface struct accessors (SDL_Surface-w, SDL_Surface-h, etc.) are in private/types.rkt.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide
 ;; Surface creation/destruction
 SDL-CreateSurface
 SDL-CreateSurfaceFrom
 SDL-DuplicateSurface
 SDL-ConvertSurface
 SDL-DestroySurface
 ;; Surface utilities
 SDL-LockSurface
 SDL-UnlockSurface
 SDL-SetSurfaceRLE
 SDL-SurfaceHasRLE
 ;; Pixel access
 SDL-ReadSurfacePixel
 SDL-WriteSurfacePixel
 SDL-ReadSurfacePixelFloat
 SDL-WriteSurfacePixelFloat
 ;; Color mapping
 SDL-MapSurfaceRGB
 SDL-MapSurfaceRGBA)

;; ============================================================================
;; Surface Creation/Destruction
;; ============================================================================

;; SDL_CreateSurface: Allocate a new surface with a specific pixel format
;; width: the width of the surface
;; height: the height of the surface
;; format: the SDL_PixelFormat for the new surface
;; Returns: a new SDL_Surface or NULL on failure
(define-sdl SDL-CreateSurface
  (_fun _int _int _SDL_PixelFormat -> _SDL_Surface-pointer/null)
  #:c-id SDL_CreateSurface)

;; SDL_CreateSurfaceFrom: Allocate a new surface with existing pixel data
;; width: the width of the surface
;; height: the height of the surface
;; format: the SDL_PixelFormat for the new surface
;; pixels: a pointer to existing pixel data
;; pitch: the number of bytes between each row of pixel data
;; Returns: a new SDL_Surface or NULL on failure
(define-sdl SDL-CreateSurfaceFrom
  (_fun _int _int _SDL_PixelFormat _pointer _int -> _SDL_Surface-pointer/null)
  #:c-id SDL_CreateSurfaceFrom)

;; SDL_DuplicateSurface: Copy a surface to a new surface
;; surface: the surface to copy
;; Returns: a copy of the surface or NULL on failure
(define-sdl SDL-DuplicateSurface
  (_fun _SDL_Surface-pointer -> _SDL_Surface-pointer/null)
  #:c-id SDL_DuplicateSurface)

;; SDL_ConvertSurface: Copy a surface to a new surface of a different format
;; surface: the surface to convert
;; format: the SDL_PixelFormat for the new surface
;; Returns: a new surface or NULL on failure
(define-sdl SDL-ConvertSurface
  (_fun _SDL_Surface-pointer _SDL_PixelFormat -> _SDL_Surface-pointer/null)
  #:c-id SDL_ConvertSurface)

;; SDL_DestroySurface: Free a surface (replaces SDL_FreeSurface from SDL2)
;; surface: the surface to destroy
(define-sdl SDL-DestroySurface (_fun _SDL_Surface-pointer -> _void)
  #:c-id SDL_DestroySurface)

;; ============================================================================
;; Surface Locking
;; ============================================================================

;; SDL_LockSurface: Set up a surface for directly accessing the pixels
;; Between calls to SDL_LockSurface/SDL_UnlockSurface, you can read/write pixels
;; Returns: true on success, false on failure
(define-sdl SDL-LockSurface
  (_fun _SDL_Surface-pointer -> _sdl-bool)
  #:c-id SDL_LockSurface)

;; SDL_UnlockSurface: Release a surface after directly accessing the pixels
(define-sdl SDL-UnlockSurface
  (_fun _SDL_Surface-pointer -> _void)
  #:c-id SDL_UnlockSurface)

;; ============================================================================
;; Surface Properties
;; ============================================================================

;; SDL_SetSurfaceRLE: Set the RLE acceleration hint for a surface
;; surface: the surface to modify
;; enabled: true to enable RLE acceleration, false to disable
;; Returns: true on success, false on failure
(define-sdl SDL-SetSurfaceRLE
  (_fun _SDL_Surface-pointer _sdl-bool -> _sdl-bool)
  #:c-id SDL_SetSurfaceRLE)

;; SDL_SurfaceHasRLE: Check whether the surface is RLE enabled
;; Returns: true if RLE is enabled, false otherwise
(define-sdl SDL-SurfaceHasRLE
  (_fun _SDL_Surface-pointer -> _sdl-bool)
  #:c-id SDL_SurfaceHasRLE)

;; ============================================================================
;; Pixel Access
;; ============================================================================

;; SDL_ReadSurfacePixel: Read a single pixel from a surface
;; surface: the surface to read from
;; x, y: coordinates of the pixel
;; r, g, b, a: pointers to receive the color components (0-255)
;; Returns: true on success, false on failure
(define-sdl SDL-ReadSurfacePixel
  (_fun _SDL_Surface-pointer _int _int
        (r : (_ptr o _uint8))
        (g : (_ptr o _uint8))
        (b : (_ptr o _uint8))
        (a : (_ptr o _uint8))
        -> (result : _sdl-bool)
        -> (values result r g b a))
  #:c-id SDL_ReadSurfacePixel)

;; SDL_WriteSurfacePixel: Write a single pixel to a surface
;; surface: the surface to write to
;; x, y: coordinates of the pixel
;; r, g, b, a: color components (0-255)
;; Returns: true on success, false on failure
(define-sdl SDL-WriteSurfacePixel
  (_fun _SDL_Surface-pointer _int _int _uint8 _uint8 _uint8 _uint8 -> _sdl-bool)
  #:c-id SDL_WriteSurfacePixel)

;; SDL_ReadSurfacePixelFloat: Read a single pixel from a surface as floats
;; surface: the surface to read from
;; x, y: coordinates of the pixel
;; r, g, b, a: pointers to receive the color components (0.0-1.0)
;; Returns: true on success, false on failure
(define-sdl SDL-ReadSurfacePixelFloat
  (_fun _SDL_Surface-pointer _int _int
        (r : (_ptr o _float))
        (g : (_ptr o _float))
        (b : (_ptr o _float))
        (a : (_ptr o _float))
        -> (result : _sdl-bool)
        -> (values result r g b a))
  #:c-id SDL_ReadSurfacePixelFloat)

;; SDL_WriteSurfacePixelFloat: Write a single pixel to a surface as floats
;; surface: the surface to write to
;; x, y: coordinates of the pixel
;; r, g, b, a: color components (0.0-1.0)
;; Returns: true on success, false on failure
(define-sdl SDL-WriteSurfacePixelFloat
  (_fun _SDL_Surface-pointer _int _int _float _float _float _float -> _sdl-bool)
  #:c-id SDL_WriteSurfacePixelFloat)

;; ============================================================================
;; Color Mapping
;; ============================================================================

;; SDL_MapSurfaceRGB: Map an RGB triple to a pixel value for a surface
;; surface: the surface to use for the mapping
;; r, g, b: color components (0-255)
;; Returns: a pixel value suitable for the surface's format
(define-sdl SDL-MapSurfaceRGB
  (_fun _SDL_Surface-pointer _uint8 _uint8 _uint8 -> _uint32)
  #:c-id SDL_MapSurfaceRGB)

;; SDL_MapSurfaceRGBA: Map an RGBA quadruple to a pixel value for a surface
;; surface: the surface to use for the mapping
;; r, g, b, a: color components (0-255)
;; Returns: a pixel value suitable for the surface's format
(define-sdl SDL-MapSurfaceRGBA
  (_fun _SDL_Surface-pointer _uint8 _uint8 _uint8 _uint8 -> _uint32)
  #:c-id SDL_MapSurfaceRGBA)
