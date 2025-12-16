#lang racket/base

;; REPL-Driven SDL3 Development
;;
;; This example demonstrates interactive SDL3 development from the REPL.
;; Unlike traditional game loops, this gives you direct control - you call
;; functions to update and render when you want.
;;
;; Note: Window close button and Cmd-Q only work during render!/run-animation!
;; because SDL requires event polling. Use (quit!) from the REPL to close.
;;
;; Usage:
;;   1. Start Racket REPL: racket -it examples/03-repl.rkt
;;   2. The window is created automatically
;;   3. Try these commands:
;;
;;      ;; Render a frame (call this to see changes)
;;      (render!)
;;
;;      ;; Change the background and render
;;      (set-bg-color! 50 20 80)
;;      (render!)
;;
;;      ;; Draw shapes
;;      (draw-rect! 100 100 200 150 '(255 0 0))
;;      (draw-circle! 400 300 80 '(0 255 0))
;;      (draw-line! 0 0 800 600 '(255 255 0))
;;      (render!)
;;
;;      ;; Clear and start fresh
;;      (clear!)
;;      (render!)
;;
;;      ;; Run an animation loop (press Escape or close window to stop)
;;      (run-animation! bouncing-rect-step)
;;
;;      ;; Clean shutdown
;;      (quit!)

(require racket/match
         racket/math
         (prefix-in sdl: sdl3/safe))

;; ============================================================================
;; State
;; ============================================================================

(define win-width 800)
(define win-height 600)

;; SDL handles
(define the-window #f)
(define the-renderer #f)

;; Background color
(define bg-color (box '(30 30 50)))

;; Shape buffer - list of shapes to draw
(define shapes (box '()))

;; ============================================================================
;; Initialization
;; ============================================================================

(define (init!)
  (unless the-window
    (sdl:sdl-init!)
    (define-values (w r)
      (sdl:make-window+renderer "SDL3 REPL - Interactive Development"
                                win-width win-height
                                #:window-flags sdl:SDL_WINDOW_RESIZABLE))
    (set! the-window w)
    (set! the-renderer r)
    (printf "SDL initialized. Window and renderer ready.~n")
    (printf "Call (render!) to draw, (help) for commands.~n")))

(define (quit!)
  (when the-renderer
    (sdl:renderer-destroy! the-renderer)
    (set! the-renderer #f))
  (when the-window
    (sdl:window-destroy! the-window)
    (set! the-window #f))
  (sdl:sdl-quit!)
  (printf "SDL shutdown complete.~n"))

;; ============================================================================
;; Drawing Commands
;; ============================================================================

(define (set-bg-color! r g b)
  (set-box! bg-color (list r g b))
  (printf "Background set to RGB(~a, ~a, ~a)~n" r g b))

(define (clear!)
  (set-box! shapes '())
  (printf "Shapes cleared.~n"))

;; Add shapes to the buffer
(define (draw-rect! x y w h color [filled? #t])
  (set-box! shapes (cons `(rect ,x ,y ,w ,h ,color ,filled?) (unbox shapes)))
  (void))

(define (draw-circle! cx cy radius color [segments 32])
  (set-box! shapes (cons `(circle ,cx ,cy ,radius ,color ,segments) (unbox shapes)))
  (void))

(define (draw-line! x1 y1 x2 y2 color)
  (set-box! shapes (cons `(line ,x1 ,y1 ,x2 ,y2 ,color) (unbox shapes)))
  (void))

(define (draw-point! x y color)
  (set-box! shapes (cons `(point ,x ,y ,color) (unbox shapes)))
  (void))

;; ============================================================================
;; Internal Drawing
;; ============================================================================

(define (render-circle! renderer cx cy radius segments)
  (define points
    (for/list ([i (in-range (+ segments 1))])
      (define angle (* 2 pi (/ i segments)))
      (list (+ cx (* radius (cos angle)))
            (+ cy (* radius (sin angle))))))
  (sdl:draw-lines! renderer points))

(define (render-shape! renderer shape)
  (match shape
    [`(rect ,x ,y ,w ,h (,r ,g ,b) ,filled?)
     (sdl:set-draw-color! renderer r g b)
     (if filled?
         (sdl:fill-rect! renderer x y w h)
         (sdl:draw-rect! renderer x y w h))]
    [`(circle ,cx ,cy ,radius (,r ,g ,b) ,segments)
     (sdl:set-draw-color! renderer r g b)
     (render-circle! renderer cx cy radius segments)]
    [`(line ,x1 ,y1 ,x2 ,y2 (,r ,g ,b))
     (sdl:set-draw-color! renderer r g b)
     (sdl:draw-line! renderer x1 y1 x2 y2)]
    [`(point ,x ,y (,r ,g ,b))
     (sdl:set-draw-color! renderer r g b)
     (sdl:draw-point! renderer x y)]
    [_ (void)]))

;; ============================================================================
;; Render
;; ============================================================================

(define (render!)
  (unless the-renderer
    (error 'render! "Not initialized. Call (init!) first."))

  ;; Process any pending events (keeps window responsive)
  (process-events!)

  ;; Check if we're still running (quit! may have been called by process-events!)
  (when the-renderer
    ;; Clear with background
    (match (unbox bg-color)
      [(list r g b) (sdl:set-draw-color! the-renderer r g b)])
    (sdl:render-clear! the-renderer)

    ;; Draw all shapes (in reverse order so first added is drawn first)
    (for ([shape (in-list (reverse (unbox shapes)))])
      (render-shape! the-renderer shape))

    ;; Present
    (sdl:render-present! the-renderer))
  (void))

;; ============================================================================
;; Event Processing
;; ============================================================================

(define (process-events!)
  (for ([ev (sdl:in-events)])
    (match ev
      [(or (sdl:quit-event) (sdl:window-event 'close-requested))
       (quit!)]
      [_ (void)])))

;; Check for quit event without blocking
(define (should-quit?)
  (for/or ([ev (sdl:in-events)])
    (match ev
      [(or (sdl:quit-event) (sdl:window-event 'close-requested)) #t]
      [(sdl:key-event 'down key _ _ _) (= key sdl:SDLK_ESCAPE)]
      [_ #f])))

;; Pump events - call this periodically to keep window responsive
;; (or just use render! which does this automatically)
(define (pump-events!)
  (process-events!))

;; ============================================================================
;; Animation Support
;; ============================================================================

;; Run an animation loop. step-fn is called each frame with no arguments.
;; It should update state and optionally modify shapes.
;; Press Escape or close window to stop.
(define (run-animation! step-fn [fps 60])
  (unless the-renderer
    (error 'run-animation! "Not initialized. Call (init!) first."))
  (define frame-time (quotient 1000 fps))
  (let loop ()
    (unless (should-quit?)
      (step-fn)
      (render!)
      (sdl:delay! frame-time)
      (loop)))
  (printf "Animation stopped.~n"))

;; ============================================================================
;; Example Animation: Bouncing Rectangle
;; ============================================================================

(define bounce-x (box 100.0))
(define bounce-y (box 100.0))
(define bounce-vx (box 4.0))
(define bounce-vy (box 3.0))
(define bounce-w 60)
(define bounce-h 40)

(define (bouncing-rect-step)
  ;; Update position
  (define x (unbox bounce-x))
  (define y (unbox bounce-y))
  (define vx (unbox bounce-vx))
  (define vy (unbox bounce-vy))

  (define new-x (+ x vx))
  (define new-y (+ y vy))

  ;; Bounce off walls
  (when (or (< new-x 0) (> (+ new-x bounce-w) win-width))
    (set-box! bounce-vx (- vx))
    (set! new-x (max 0 (min (- win-width bounce-w) new-x))))
  (when (or (< new-y 0) (> (+ new-y bounce-h) win-height))
    (set-box! bounce-vy (- vy))
    (set! new-y (max 0 (min (- win-height bounce-h) new-y))))

  (set-box! bounce-x new-x)
  (set-box! bounce-y new-y)

  ;; Clear and draw
  (set-box! shapes '())
  (draw-rect! new-x new-y bounce-w bounce-h '(100 200 255)))

;; ============================================================================
;; Help
;; ============================================================================

(define (help)
  (printf "~n")
  (printf "=== SDL3 REPL Commands ===~n")
  (printf "~n")
  (printf "Setup:~n")
  (printf "  (init!)              - Initialize SDL (auto-called on load)~n")
  (printf "  (quit!)              - Shutdown SDL and close window~n")
  (printf "~n")
  (printf "Drawing:~n")
  (printf "  (set-bg-color! r g b)              - Set background color~n")
  (printf "  (draw-rect! x y w h color [fill?]) - Add rectangle~n")
  (printf "  (draw-circle! x y r color)         - Add circle~n")
  (printf "  (draw-line! x1 y1 x2 y2 color)     - Add line~n")
  (printf "  (draw-point! x y color)            - Add point~n")
  (printf "  (clear!)                           - Clear all shapes~n")
  (printf "  (render!)                          - Draw frame~n")
  (printf "~n")
  (printf "Colors are lists: '(255 0 0) for red~n")
  (printf "~n")
  (printf "Animation:~n")
  (printf "  (run-animation! step-fn [fps])     - Run animation loop~n")
  (printf "  (run-animation! bouncing-rect-step) - Demo animation~n")
  (printf "~n")
  (printf "Note: Close button/Cmd-Q only work during render! or animation.~n")
  (printf "      Use (quit!) from REPL to close the window.~n")
  (printf "~n")
  (printf "Example session:~n")
  (printf "  (set-bg-color! 20 20 40)~n")
  (printf "  (draw-rect! 100 100 200 150 '(255 100 50))~n")
  (printf "  (draw-circle! 500 300 80 '(50 200 100))~n")
  (printf "  (render!)~n")
  (printf "~n"))

;; ============================================================================
;; Exports
;; ============================================================================

(provide init!
         quit!
         set-bg-color!
         clear!
         draw-rect!
         draw-circle!
         draw-line!
         draw-point!
         render!
         run-animation!
         bouncing-rect-step
         bounce-x bounce-y bounce-vx bounce-vy
         help)

;; ============================================================================
;; Auto-initialize on load
;; ============================================================================

(init!)
(render!)
(help)
