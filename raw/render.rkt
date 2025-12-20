#lang racket/base

;; SDL3 Renderer and Drawing Primitives
;;
;; Functions for creating renderers and drawing shapes.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide ;; Renderer creation/destruction
         SDL-CreateRenderer
         SDL-DestroyRenderer
         SDL-SetRenderDrawColor
         SDL-RenderClear
         SDL-RenderPresent
         ;; Renderer query functions
         SDL-GetNumRenderDrivers
         SDL-GetRenderDriver
         SDL-GetRenderer
         SDL-GetRenderWindow
         SDL-GetRendererName
         SDL-GetRenderOutputSize
         SDL-GetCurrentRenderOutputSize
         SDL-GetRenderDrawColor
         SDL-SetRenderDrawColorFloat
         SDL-GetRenderDrawColorFloat
         SDL-SetRenderVSync
         SDL-GetRenderVSync
         ;; Viewport and clipping
         SDL-SetRenderViewport
         SDL-GetRenderViewport
         SDL-SetRenderClipRect
         SDL-GetRenderClipRect
         SDL-RenderClipEnabled
         SDL-SetRenderScale
         SDL-GetRenderScale
         ;; Drawing primitives
         SDL-RenderPoint
         SDL-RenderPoints
         SDL-RenderLine
         SDL-RenderLines
         SDL-RenderRect
         SDL-RenderRects
         SDL-RenderFillRect
         SDL-RenderFillRects
         ;; Geometry rendering
         SDL-RenderGeometry
         ;; Debug text
         SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE
         SDL-RenderDebugText
         ;; Blend modes
         SDL-SetRenderDrawBlendMode
         SDL-GetRenderDrawBlendMode
         ;; Screenshots
         SDL-RenderReadPixels
         ;; Rectangle utilities
         SDL-HasRectIntersection
         SDL-GetRectIntersection
         SDL-HasRectIntersectionFloat
         SDL-GetRectIntersectionFloat
         SDL-GetRectUnion
         SDL-GetRectUnionFloat
         SDL-GetRectEnclosingPoints
         SDL-GetRectEnclosingPointsFloat
         SDL-GetRectAndLineIntersection
         SDL-GetRectAndLineIntersectionFloat)

;; ============================================================================
;; Renderer Creation/Destruction
;; ============================================================================

;; SDL_CreateRenderer: Create a 2D rendering context for a window
;; window: The window for the renderer
;; name: The name of the renderer driver, or NULL for default
;; Returns: Pointer to the renderer, or NULL on failure
(define-sdl SDL-CreateRenderer
  (_fun _SDL_Window-pointer _string/utf-8 -> _SDL_Renderer-pointer/null)
  #:c-id SDL_CreateRenderer)

;; SDL_DestroyRenderer: Destroy a renderer
(define-sdl SDL-DestroyRenderer (_fun _SDL_Renderer-pointer -> _void)
  #:c-id SDL_DestroyRenderer)

;; SDL_SetRenderDrawColor: Set the color for drawing operations
;; r, g, b, a: Color components (0-255)
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderDrawColor
  (_fun _SDL_Renderer-pointer _uint8 _uint8 _uint8 _uint8 -> _sdl-bool)
  #:c-id SDL_SetRenderDrawColor)

;; SDL_RenderClear: Clear the renderer with the current draw color
;; Returns: true on success, false on failure
(define-sdl SDL-RenderClear (_fun _SDL_Renderer-pointer -> _sdl-bool)
  #:c-id SDL_RenderClear)

;; SDL_RenderPresent: Update the screen with any rendering since the last call
;; Returns: true on success, false on failure
(define-sdl SDL-RenderPresent (_fun _SDL_Renderer-pointer -> _sdl-bool)
  #:c-id SDL_RenderPresent)

;; ============================================================================
;; Renderer Query Functions
;; ============================================================================

;; SDL_GetNumRenderDrivers: Get the number of 2D rendering drivers available
;; Returns: the number of built-in render drivers
(define-sdl SDL-GetNumRenderDrivers (_fun -> _int)
  #:c-id SDL_GetNumRenderDrivers)

;; SDL_GetRenderDriver: Get the name of a built-in 2D rendering driver
;; index: the index of the rendering driver (0 to SDL_GetNumRenderDrivers()-1)
;; Returns: the name of the rendering driver, or NULL if invalid index
(define-sdl SDL-GetRenderDriver (_fun _int -> _string/utf-8)
  #:c-id SDL_GetRenderDriver)

;; SDL_GetRenderer: Get the renderer associated with a window
;; window: the window to query
;; Returns: the rendering context, or NULL on failure
(define-sdl SDL-GetRenderer
  (_fun _SDL_Window-pointer -> _SDL_Renderer-pointer/null)
  #:c-id SDL_GetRenderer)

;; SDL_GetRenderWindow: Get the window associated with a renderer
;; renderer: the renderer to query
;; Returns: the window, or NULL on failure
(define-sdl SDL-GetRenderWindow
  (_fun _SDL_Renderer-pointer -> _SDL_Window-pointer/null)
  #:c-id SDL_GetRenderWindow)

;; SDL_GetRendererName: Get the name of a renderer
;; renderer: the rendering context
;; Returns: the name of the selected renderer, or NULL on failure
(define-sdl SDL-GetRendererName (_fun _SDL_Renderer-pointer -> _string/utf-8)
  #:c-id SDL_GetRendererName)

;; SDL_GetRenderOutputSize: Get the output size in pixels of a rendering context
;; renderer: the rendering context
;; Returns: (values success? width height)
(define-sdl SDL-GetRenderOutputSize
  (_fun _SDL_Renderer-pointer
        (w : (_ptr o _int))
        (h : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result w h))
  #:c-id SDL_GetRenderOutputSize)

;; SDL_GetCurrentRenderOutputSize: Get the current output size in pixels
;; This returns the size considering the current render target and logical size.
;; renderer: the rendering context
;; Returns: (values success? width height)
(define-sdl SDL-GetCurrentRenderOutputSize
  (_fun _SDL_Renderer-pointer
        (w : (_ptr o _int))
        (h : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result w h))
  #:c-id SDL_GetCurrentRenderOutputSize)

;; SDL_GetRenderDrawColor: Get the color used for drawing operations
;; renderer: the rendering context
;; Returns: (values success? r g b a)
(define-sdl SDL-GetRenderDrawColor
  (_fun _SDL_Renderer-pointer
        (r : (_ptr o _uint8))
        (g : (_ptr o _uint8))
        (b : (_ptr o _uint8))
        (a : (_ptr o _uint8))
        -> (result : _sdl-bool)
        -> (values result r g b a))
  #:c-id SDL_GetRenderDrawColor)

;; SDL_SetRenderDrawColorFloat: Set the color for drawing operations (float version)
;; renderer: the rendering context
;; r, g, b, a: Color components (0.0 to 1.0, can exceed for HDR)
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderDrawColorFloat
  (_fun _SDL_Renderer-pointer _float _float _float _float -> _sdl-bool)
  #:c-id SDL_SetRenderDrawColorFloat)

;; SDL_GetRenderDrawColorFloat: Get the color used for drawing operations (float version)
;; renderer: the rendering context
;; Returns: (values success? r g b a)
(define-sdl SDL-GetRenderDrawColorFloat
  (_fun _SDL_Renderer-pointer
        (r : (_ptr o _float))
        (g : (_ptr o _float))
        (b : (_ptr o _float))
        (a : (_ptr o _float))
        -> (result : _sdl-bool)
        -> (values result r g b a))
  #:c-id SDL_GetRenderDrawColorFloat)

;; SDL_SetRenderVSync: Toggle VSync for a renderer
;; renderer: the rendering context
;; vsync: the vertical refresh sync interval (1 for on, 0 for off, -1 for adaptive)
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderVSync
  (_fun _SDL_Renderer-pointer _int -> _sdl-bool)
  #:c-id SDL_SetRenderVSync)

;; SDL_GetRenderVSync: Get the VSync setting for a renderer
;; renderer: the rendering context
;; Returns: (values success? vsync)
(define-sdl SDL-GetRenderVSync
  (_fun _SDL_Renderer-pointer
        (vsync : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result vsync))
  #:c-id SDL_GetRenderVSync)

;; ============================================================================
;; Viewport and Clipping
;; ============================================================================

;; SDL_SetRenderViewport: Set the drawing area for rendering on the current target
;; renderer: the rendering context
;; rect: the SDL_Rect representing the drawing area, or NULL to set the viewport
;;       to the entire target
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderViewport
  (_fun _SDL_Renderer-pointer _SDL_Rect-pointer/null -> _sdl-bool)
  #:c-id SDL_SetRenderViewport)

;; SDL_GetRenderViewport: Get the drawing area for the current target
;; renderer: the rendering context
;; rect: an SDL_Rect structure to be filled with the current drawing area
;; Returns: true on success, false on failure
(define-sdl SDL-GetRenderViewport
  (_fun _SDL_Renderer-pointer _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetRenderViewport)

;; SDL_SetRenderClipRect: Set the clip rectangle for rendering on the current target
;; renderer: the rendering context
;; rect: an SDL_Rect representing the clip area, or NULL to disable clipping
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderClipRect
  (_fun _SDL_Renderer-pointer _SDL_Rect-pointer/null -> _sdl-bool)
  #:c-id SDL_SetRenderClipRect)

;; SDL_GetRenderClipRect: Get the clip rectangle for the current target
;; renderer: the rendering context
;; rect: an SDL_Rect structure to be filled with the current clip rectangle
;; Returns: true on success, false on failure
(define-sdl SDL-GetRenderClipRect
  (_fun _SDL_Renderer-pointer _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetRenderClipRect)

;; SDL_RenderClipEnabled: Get whether clipping is enabled on the given render target
;; renderer: the rendering context
;; Returns: true if clipping is enabled, false if not
(define-sdl SDL-RenderClipEnabled
  (_fun _SDL_Renderer-pointer -> _stdbool)
  #:c-id SDL_RenderClipEnabled)

;; SDL_SetRenderScale: Set the drawing scale for rendering on the current target
;; renderer: the rendering context
;; scaleX: the horizontal scaling factor
;; scaleY: the vertical scaling factor
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderScale
  (_fun _SDL_Renderer-pointer _float _float -> _sdl-bool)
  #:c-id SDL_SetRenderScale)

;; SDL_GetRenderScale: Get the drawing scale for the current target
;; renderer: the rendering context
;; Returns: (values success? scaleX scaleY)
(define-sdl SDL-GetRenderScale
  (_fun _SDL_Renderer-pointer
        (scaleX : (_ptr o _float))
        (scaleY : (_ptr o _float))
        -> (result : _sdl-bool)
        -> (values result scaleX scaleY))
  #:c-id SDL_GetRenderScale)

;; ============================================================================
;; Drawing Primitives
;; ============================================================================

;; SDL_RenderPoint: Draw a point (single pixel) at (x, y)
;; renderer: the renderer to draw on
;; x, y: coordinates of the point
;; Returns: true on success, false on failure
(define-sdl SDL-RenderPoint
  (_fun _SDL_Renderer-pointer _float _float -> _sdl-bool)
  #:c-id SDL_RenderPoint)

;; SDL_RenderPoints: Draw multiple points at once
;; renderer: the renderer to draw on
;; points: pointer to array of SDL_FPoint structs
;; count: number of points to draw
;; Returns: true on success, false on failure
(define-sdl SDL-RenderPoints
  (_fun _SDL_Renderer-pointer _pointer _int -> _sdl-bool)
  #:c-id SDL_RenderPoints)

;; SDL_RenderLine: Draw a line from (x1, y1) to (x2, y2)
;; renderer: the renderer to draw on
;; x1, y1: start point coordinates
;; x2, y2: end point coordinates
;; Returns: true on success, false on failure
(define-sdl SDL-RenderLine
  (_fun _SDL_Renderer-pointer _float _float _float _float -> _sdl-bool)
  #:c-id SDL_RenderLine)

;; SDL_RenderLines: Draw a series of connected lines
;; renderer: the renderer to draw on
;; points: pointer to array of SDL_FPoint structs (vertices)
;; count: number of points (draws count-1 lines)
;; Returns: true on success, false on failure
(define-sdl SDL-RenderLines
  (_fun _SDL_Renderer-pointer _pointer _int -> _sdl-bool)
  #:c-id SDL_RenderLines)

;; SDL_RenderRect: Draw a rectangle outline
;; renderer: the renderer to draw on
;; rect: the rectangle to draw (NULL draws the entire renderer)
;; Returns: true on success, false on failure
(define-sdl SDL-RenderRect
  (_fun _SDL_Renderer-pointer _SDL_FRect-pointer/null -> _sdl-bool)
  #:c-id SDL_RenderRect)

;; SDL_RenderRects: Draw multiple rectangle outlines at once
;; renderer: the renderer to draw on
;; rects: pointer to array of SDL_FRect structs
;; count: number of rectangles to draw
;; Returns: true on success, false on failure
(define-sdl SDL-RenderRects
  (_fun _SDL_Renderer-pointer _pointer _int -> _sdl-bool)
  #:c-id SDL_RenderRects)

;; SDL_RenderFillRect: Draw a filled rectangle
;; renderer: the renderer to draw on
;; rect: the rectangle to fill (NULL fills the entire renderer)
;; Returns: true on success, false on failure
(define-sdl SDL-RenderFillRect
  (_fun _SDL_Renderer-pointer _SDL_FRect-pointer/null -> _sdl-bool)
  #:c-id SDL_RenderFillRect)

;; SDL_RenderFillRects: Draw multiple filled rectangles at once
;; renderer: the renderer to draw on
;; rects: pointer to array of SDL_FRect structs
;; count: number of rectangles to fill
;; Returns: true on success, false on failure
(define-sdl SDL-RenderFillRects
  (_fun _SDL_Renderer-pointer _pointer _int -> _sdl-bool)
  #:c-id SDL_RenderFillRects)

;; ============================================================================
;; Geometry Rendering
;; ============================================================================

;; SDL_RenderGeometry: Render a list of triangles
;; renderer: the rendering context
;; texture: optional texture for textured triangles (NULL for solid colors)
;; vertices: pointer to array of SDL_Vertex structs
;; num_vertices: number of vertices
;; indices: optional array of indices into vertices (NULL for sequential)
;; num_indices: number of indices (0 if indices is NULL)
;; Returns: true on success, false on failure
(define-sdl SDL-RenderGeometry
  (_fun _SDL_Renderer-pointer
        _SDL_Texture-pointer/null
        _pointer          ; vertices array
        _int              ; num_vertices
        _pointer          ; indices array (can be NULL)
        _int              ; num_indices
        -> _sdl-bool)
  #:c-id SDL_RenderGeometry)

;; ============================================================================
;; Debug Text
;; ============================================================================

;; SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE: Size of debug text characters (8x8 pixels)
(define SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE 8)

;; SDL_RenderDebugText: Draw debug text to a renderer
;; This is a simple 8x8 bitmap font for debugging purposes.
;; renderer: the renderer to draw on
;; x, y: position of top-left corner
;; str: the string to render (UTF-8, but only ASCII is rendered)
;; Returns: true on success, false on failure
(define-sdl SDL-RenderDebugText
  (_fun _SDL_Renderer-pointer _float _float _string/utf-8 -> _sdl-bool)
  #:c-id SDL_RenderDebugText)

;; ============================================================================
;; Blend Modes
;; ============================================================================

;; SDL_SetRenderDrawBlendMode: Set the blend mode used for drawing operations
;; renderer: the renderer
;; blendMode: the blend mode to use
;; Returns: true on success, false on failure
(define-sdl SDL-SetRenderDrawBlendMode
  (_fun _SDL_Renderer-pointer _SDL_BlendMode -> _sdl-bool)
  #:c-id SDL_SetRenderDrawBlendMode)

;; SDL_GetRenderDrawBlendMode: Get the current blend mode for the renderer
;; renderer: the renderer to query
;; blendMode: pointer to receive the current blend mode
;; Returns: true on success, false on failure
(define-sdl SDL-GetRenderDrawBlendMode
  (_fun _SDL_Renderer-pointer (blendMode : (_ptr o _SDL_BlendMode))
        -> (result : _sdl-bool)
        -> (values result blendMode))
  #:c-id SDL_GetRenderDrawBlendMode)

;; ============================================================================
;; Screenshots
;; ============================================================================

;; SDL_RenderReadPixels: Read pixels from the current rendering target to a surface
;; renderer: the rendering context
;; rect: area to read (NULL for entire render target)
;; Returns: a new surface with the pixels, or NULL on failure
;;
;; Use with IMG_SavePNG or IMG_SaveJPG to save screenshots.
(define-sdl SDL-RenderReadPixels
  (_fun _SDL_Renderer-pointer _SDL_Rect-pointer/null -> _SDL_Surface-pointer/null)
  #:c-id SDL_RenderReadPixels)

;; ============================================================================
;; Rectangle Utilities
;; ============================================================================

;; SDL_HasRectIntersection: Determine whether two rectangles intersect
;; A: an SDL_Rect structure representing the first rectangle
;; B: an SDL_Rect structure representing the second rectangle
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-HasRectIntersection
  (_fun _SDL_Rect-pointer _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_HasRectIntersection)

;; SDL_GetRectIntersection: Calculate the intersection of two rectangles
;; A: an SDL_Rect structure representing the first rectangle
;; B: an SDL_Rect structure representing the second rectangle
;; result: an SDL_Rect structure to be filled with the intersection
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-GetRectIntersection
  (_fun _SDL_Rect-pointer _SDL_Rect-pointer _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetRectIntersection)

;; SDL_HasRectIntersectionFloat: Determine whether two float rectangles intersect
;; A: an SDL_FRect structure representing the first rectangle
;; B: an SDL_FRect structure representing the second rectangle
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-HasRectIntersectionFloat
  (_fun _SDL_FRect-pointer _SDL_FRect-pointer -> _sdl-bool)
  #:c-id SDL_HasRectIntersectionFloat)

;; SDL_GetRectIntersectionFloat: Calculate the intersection of two float rectangles
;; A: an SDL_FRect structure representing the first rectangle
;; B: an SDL_FRect structure representing the second rectangle
;; result: an SDL_FRect structure to be filled with the intersection
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-GetRectIntersectionFloat
  (_fun _SDL_FRect-pointer _SDL_FRect-pointer _SDL_FRect-pointer -> _sdl-bool)
  #:c-id SDL_GetRectIntersectionFloat)

;; SDL_GetRectUnion: Calculate the union of two rectangles
;; A: first rectangle
;; B: second rectangle
;; result: filled with the union of A and B
;; Returns: true on success, false on failure
(define-sdl SDL-GetRectUnion
  (_fun _SDL_Rect-pointer _SDL_Rect-pointer _SDL_Rect-pointer -> _sdl-bool)
  #:c-id SDL_GetRectUnion)

;; SDL_GetRectUnionFloat: Calculate the union of two float rectangles
;; A: first rectangle
;; B: second rectangle
;; result: filled with the union of A and B
;; Returns: true on success, false on failure
(define-sdl SDL-GetRectUnionFloat
  (_fun _SDL_FRect-pointer _SDL_FRect-pointer _SDL_FRect-pointer -> _sdl-bool)
  #:c-id SDL_GetRectUnionFloat)

;; SDL_GetRectEnclosingPoints: Calculate a minimal rect enclosing points
;; points: array of SDL_Point
;; count: number of points
;; clip: optional clipping rect (can be NULL)
;; result: filled with the enclosing rect
;; Returns: true if any points were enclosed, false otherwise
(define-sdl SDL-GetRectEnclosingPoints
  (_fun _pointer _int _SDL_Rect-pointer/null _SDL_Rect-pointer
        -> _sdl-bool)
  #:c-id SDL_GetRectEnclosingPoints)

;; SDL_GetRectEnclosingPointsFloat: Calculate a minimal rect enclosing points
;; points: array of SDL_FPoint
;; count: number of points
;; clip: optional clipping rect (can be NULL)
;; result: filled with the enclosing rect
;; Returns: true if any points were enclosed, false otherwise
(define-sdl SDL-GetRectEnclosingPointsFloat
  (_fun _pointer _int _SDL_FRect-pointer/null _SDL_FRect-pointer
        -> _sdl-bool)
  #:c-id SDL_GetRectEnclosingPointsFloat)

;; SDL_GetRectAndLineIntersection: Clip a line segment to a rectangle
;; rect: rectangle to intersect
;; x1, y1, x2, y2: line endpoints (modified in place)
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-GetRectAndLineIntersection
  (_fun _SDL_Rect-pointer
        (x1 : (_ptr io _int))
        (y1 : (_ptr io _int))
        (x2 : (_ptr io _int))
        (y2 : (_ptr io _int))
        -> (result : _sdl-bool)
        -> (values result x1 y1 x2 y2))
  #:c-id SDL_GetRectAndLineIntersection)

;; SDL_GetRectAndLineIntersectionFloat: Clip a line segment to a float rect
;; rect: rectangle to intersect
;; x1, y1, x2, y2: line endpoints (modified in place)
;; Returns: true if there is an intersection, false otherwise
(define-sdl SDL-GetRectAndLineIntersectionFloat
  (_fun _SDL_FRect-pointer
        (x1 : (_ptr io _float))
        (y1 : (_ptr io _float))
        (x2 : (_ptr io _float))
        (y2 : (_ptr io _float))
        -> (result : _sdl-bool)
        -> (values result x1 y1 x2 y2))
  #:c-id SDL_GetRectAndLineIntersectionFloat)
