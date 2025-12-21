#lang racket/base

;; SDL3 OpenGL Functions
;;
;; Functions for OpenGL context creation and management.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-GL-LoadLibrary
         SDL-GL-GetProcAddress
         SDL-GL-UnloadLibrary
         SDL-GL-ExtensionSupported
         SDL-GL-ResetAttributes
         SDL-GL-SetAttribute
         SDL-GL-GetAttribute
         SDL-GL-CreateContext
         SDL-GL-MakeCurrent
         SDL-GL-GetCurrentWindow
         SDL-GL-GetCurrentContext
         SDL-GL-SetSwapInterval
         SDL-GL-GetSwapInterval
         SDL-GL-SwapWindow
         SDL-GL-DestroyContext)

;; ============================================================================
;; OpenGL Loading
;; ============================================================================

;; SDL_GL_LoadLibrary: Dynamically load an OpenGL library
;; path: filename to load, or #f for default
;; Returns: #t on success, #f on failure
(define-sdl SDL-GL-LoadLibrary (_fun _string/utf-8 -> _sdl-bool)
  #:c-id SDL_GL_LoadLibrary)

;; SDL_GL_GetProcAddress: Get an OpenGL function address
;; proc: name of the function
;; Returns: pointer to the function, or #f
(define-sdl SDL-GL-GetProcAddress (_fun _string/utf-8 -> _pointer)
  #:c-id SDL_GL_GetProcAddress)

;; SDL_GL_UnloadLibrary: Unload the OpenGL library
(define-sdl SDL-GL-UnloadLibrary (_fun -> _void)
  #:c-id SDL_GL_UnloadLibrary)

;; ============================================================================
;; OpenGL Configuration
;; ============================================================================

;; SDL_GL_ExtensionSupported: Check if an OpenGL extension is supported
;; extension: name of the extension
;; Returns: #t if supported, #f otherwise
(define-sdl SDL-GL-ExtensionSupported (_fun _string/utf-8 -> _sdl-bool)
  #:c-id SDL_GL_ExtensionSupported)

;; SDL_GL_ResetAttributes: Reset all GL attributes to default values
(define-sdl SDL-GL-ResetAttributes (_fun -> _void)
  #:c-id SDL_GL_ResetAttributes)

;; SDL_GL_SetAttribute: Set an OpenGL attribute
;; attr: the attribute to set (SDL_GLAttr)
;; value: the value to set
;; Returns: #t on success, #f on failure
(define-sdl SDL-GL-SetAttribute (_fun _SDL_GLAttr _int -> _sdl-bool)
  #:c-id SDL_GL_SetAttribute)

;; SDL_GL_GetAttribute: Get an OpenGL attribute
;; attr: the attribute to query (SDL_GLAttr)
;; Returns: (values success? value)
(define-sdl SDL-GL-GetAttribute
  (_fun _SDL_GLAttr (val : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result val))
  #:c-id SDL_GL_GetAttribute)

;; ============================================================================
;; OpenGL Context
;; ============================================================================

;; SDL_GL_CreateContext: Create an OpenGL context for a window
;; window: the window to associate with the context
;; Returns: the context, or #f on failure
(define-sdl SDL-GL-CreateContext (_fun _SDL_Window-pointer -> _SDL_GLContext-pointer/null)
  #:c-id SDL_GL_CreateContext)

;; SDL_GL_MakeCurrent: Set up an OpenGL context for rendering into an OpenGL window
;; window: the window
;; context: the context
;; Returns: #t on success, #f on failure
(define-sdl SDL-GL-MakeCurrent (_fun _SDL_Window-pointer _SDL_GLContext-pointer -> _sdl-bool)
  #:c-id SDL_GL_MakeCurrent)

;; SDL_GL_GetCurrentWindow: Get the currently active OpenGL window
;; Returns: the window, or #f
(define-sdl SDL-GL-GetCurrentWindow (_fun -> _SDL_Window-pointer/null)
  #:c-id SDL_GL_GetCurrentWindow)

;; SDL_GL_GetCurrentContext: Get the currently active OpenGL context
;; Returns: the context, or #f
(define-sdl SDL-GL-GetCurrentContext (_fun -> _SDL_GLContext-pointer/null)
  #:c-id SDL_GL_GetCurrentContext)

;; SDL_GL_DestroyContext: Delete an OpenGL context
;; context: the context to delete
(define-sdl SDL-GL-DestroyContext (_fun _SDL_GLContext-pointer -> _void)
  #:c-id SDL_GL_DestroyContext)

;; ============================================================================
;; OpenGL Swap
;; ============================================================================

;; SDL_GL_SetSwapInterval: Set the swap interval (vsync)
;; interval: 0 for immediate, 1 for vsync, -1 for adaptive vsync
;; Returns: #t on success, #f on failure
(define-sdl SDL-GL-SetSwapInterval (_fun _int -> _sdl-bool)
  #:c-id SDL_GL_SetSwapInterval)

;; SDL_GL_GetSwapInterval: Get the swap interval
;; Returns: (values success? interval)
(define-sdl SDL-GL-GetSwapInterval
  (_fun (val : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result val))
  #:c-id SDL_GL_GetSwapInterval)

;; SDL_GL_SwapWindow: Swap the OpenGL buffers for a window
;; window: the window
;; Returns: #t on success, #f on failure
(define-sdl SDL-GL-SwapWindow (_fun _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_GL_SwapWindow)
