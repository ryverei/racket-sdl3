#lang racket/base

;; Geometry Rendering Demo
;;
;; Demonstrates SDL_RenderGeometry for hardware-accelerated arbitrary triangles:
;; - Colored triangles with per-vertex colors
;; - Simple particle system using geometry rendering
;; - Indexed geometry for efficient rendering
;;
;; Controls:
;;   1 - Show colored triangles demo
;;   2 - Show indexed quad demo
;;   3 - Show particle system demo
;;   SPACE - Reset particles (in particle mode)
;;   ESC - Quit

(require racket/match
         racket/format
         racket/math
         sdl3)

(define window-width 800)
(define window-height 600)
(define window-title "SDL3 Geometry Rendering Demo")

;; Demo modes
(define MODE-TRIANGLES 1)
(define MODE-INDEXED 2)
(define MODE-PARTICLES 3)

;; Particle system
(struct particle (x y vx vy r g b life) #:mutable)

(define particles '())
(define max-particles 200)

(define (make-random-particle)
  (particle (+ 400.0 (* 50 (- (random) 0.5)))  ; x near center
            (+ 300.0 (* 50 (- (random) 0.5)))  ; y near center
            (* 4.0 (- (random) 0.5))           ; vx
            (* 4.0 (- (random) 0.5))           ; vy
            (+ 0.5 (* 0.5 (random)))           ; r
            (+ 0.5 (* 0.5 (random)))           ; g
            (+ 0.5 (* 0.5 (random)))           ; b
            1.0))                               ; life

(define (reset-particles!)
  (set! particles
    (for/list ([_ (in-range max-particles)])
      (make-random-particle))))

(define (update-particle! p dt)
  ;; Apply gravity
  (set-particle-vy! p (+ (particle-vy p) (* 0.1 dt)))
  ;; Update position
  (set-particle-x! p (+ (particle-x p) (* (particle-vx p) dt)))
  (set-particle-y! p (+ (particle-y p) (* (particle-vy p) dt)))
  ;; Fade out
  (set-particle-life! p (- (particle-life p) (* 0.01 dt)))
  ;; Respawn if dead or off-screen
  (when (or (<= (particle-life p) 0)
            (> (particle-y p) 650))
    (define new-p (make-random-particle))
    (set-particle-x! p (particle-x new-p))
    (set-particle-y! p (particle-y new-p))
    (set-particle-vx! p (particle-vx new-p))
    (set-particle-vy! p (particle-vy new-p))
    (set-particle-r! p (particle-r new-p))
    (set-particle-g! p (particle-g new-p))
    (set-particle-b! p (particle-b new-p))
    (set-particle-life! p 1.0)))

;; Draw colored triangles demo
(define (draw-triangles-demo renderer)
  (set-draw-color! renderer 30 30 40)
  (render-clear! renderer)

  ;; Draw instructions
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "COLORED TRIANGLES - Per-vertex colors with smooth interpolation")

  ;; Triangle 1: Red-Green-Blue gradient
  (define tri1
    (list (make-vertex 200 100  1.0 0.0 0.0)    ; top - red
          (make-vertex 100 300  0.0 1.0 0.0)    ; bottom-left - green
          (make-vertex 300 300  0.0 0.0 1.0)))  ; bottom-right - blue
  (render-geometry! renderer tri1)

  ;; Triangle 2: Cyan-Magenta-Yellow gradient
  (define tri2
    (list (make-vertex 500 100  0.0 1.0 1.0)    ; top - cyan
          (make-vertex 400 300  1.0 0.0 1.0)    ; bottom-left - magenta
          (make-vertex 600 300  1.0 1.0 0.0)))  ; bottom-right - yellow
  (render-geometry! renderer tri2)

  ;; Triangle 3: White center fading to transparent edges
  (define tri3
    (list (make-vertex 350 400  1.0 1.0 1.0 1.0)    ; top - white opaque
          (make-vertex 250 550  1.0 1.0 1.0 0.2)    ; bottom-left - faded
          (make-vertex 450 550  1.0 1.0 1.0 0.2)))  ; bottom-right - faded
  (render-geometry! renderer tri3)

  ;; Triangle 4: Fire colors
  (define tri4
    (list (make-vertex 650 350  1.0 1.0 0.0)    ; top - yellow
          (make-vertex 550 550  1.0 0.0 0.0)    ; bottom-left - red
          (make-vertex 750 550  1.0 0.5 0.0)))  ; bottom-right - orange
  (render-geometry! renderer tri4)

  ;; Labels
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer 150 320 "RGB Gradient")
  (render-debug-text! renderer 450 320 "CMY Gradient")
  (render-debug-text! renderer 300 560 "Alpha Fade")
  (render-debug-text! renderer 610 560 "Fire Colors"))

;; Draw indexed quad demo - show how indices work
(define (draw-indexed-demo renderer frame)
  (set-draw-color! renderer 30 30 40)
  (render-clear! renderer)

  ;; Draw instructions
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "INDEXED GEOMETRY - 4 vertices, 6 indices make 2 triangles (quad)")

  ;; Animate colors
  (define t (* frame 0.03))
  (define r1 (* 0.5 (+ 1.0 (sin t))))
  (define g1 (* 0.5 (+ 1.0 (sin (+ t 2.0)))))
  (define b1 (* 0.5 (+ 1.0 (sin (+ t 4.0)))))

  ;; Define 4 vertices for a quad
  (define vertices
    (list (make-vertex 200 150  r1 0.2 0.2)          ; 0: top-left
          (make-vertex 600 150  0.2 g1 0.2)          ; 1: top-right
          (make-vertex 600 450  0.2 0.2 b1)          ; 2: bottom-right
          (make-vertex 200 450  0.8 0.8 0.2)))       ; 3: bottom-left

  ;; Two triangles using indices: (0,1,2) and (0,2,3)
  (define indices '(0 1 2  0 2 3))

  (render-geometry! renderer vertices #:indices indices)

  ;; Draw vertex labels
  (set-draw-color! renderer 255 255 255)
  (render-debug-text! renderer 180 130 "V0 (0,1,2)")
  (render-debug-text! renderer 605 150 "V1")
  (render-debug-text! renderer 605 450 "V2")
  (render-debug-text! renderer 150 450 "V3 (0,2,3)")

  ;; Explanation
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer 10 500 "4 vertices define corners, 6 indices define 2 triangles")
  (render-debug-text! renderer 10 515 "Triangle 1: V0-V1-V2 | Triangle 2: V0-V2-V3")
  (render-debug-text! renderer 10 530 "This is more efficient than specifying 6 vertices"))

;; Draw particle system demo
(define (draw-particles-demo renderer)
  (set-draw-color! renderer 10 10 20)
  (render-clear! renderer)

  ;; Draw instructions
  (set-draw-color! renderer 255 255 0)
  (render-debug-text! renderer 10 10 "PARTICLE SYSTEM - Many triangles rendered efficiently")
  (render-debug-text! renderer 10 25 "SPACE to reset particles")

  ;; Update particles
  (for ([p (in-list particles)])
    (update-particle! p 1.0))

  ;; Build vertex list for all particles
  ;; Each particle is a small triangle
  (define size 8.0)
  (define all-vertices
    (for/fold ([verts '()])
              ([p (in-list particles)])
      (define x (particle-x p))
      (define y (particle-y p))
      (define r (particle-r p))
      (define g (particle-g p))
      (define b (particle-b p))
      (define a (particle-life p))
      ;; Triangle pointing up
      (append verts
              (list (make-vertex x (- y size) r g b a)           ; top
                    (make-vertex (- x size) (+ y size) r g b a)  ; bottom-left
                    (make-vertex (+ x size) (+ y size) r g b a))); bottom-right
      ))

  ;; Render all particles in one call
  (when (not (null? all-vertices))
    (render-geometry! renderer all-vertices))

  ;; Show particle count
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer 10 (- window-height 30)
                       (~a "Particles: " (length particles)
                           " | Triangles: " (length particles)
                           " | Vertices: " (* 3 (length particles)))))

(define (main)
  (sdl-init!)

  (define-values (window renderer)
    (make-window+renderer window-title window-width window-height
                          #:window-flags SDL_WINDOW_RESIZABLE))

  ;; Initialize particles
  (reset-particles!)

  (let loop ([running? #t]
             [mode MODE-TRIANGLES]
             [frame 0])
    (when running?
      ;; Handle events
      (define-values (still-running? new-mode)
        (for/fold ([run? #t]
                   [m mode])
                  ([ev (in-events)]
                   #:break (not run?))
          (match ev
            [(or (quit-event) (window-event 'close-requested))
             (values #f m)]

            [(key-event 'down key _ _ _)
             (cond
               [(= key SDLK_ESCAPE) (values #f m)]
               [(= key SDLK_1) (values run? MODE-TRIANGLES)]
               [(= key SDLK_2) (values run? MODE-INDEXED)]
               [(= key SDLK_3) (values run? MODE-PARTICLES)]
               [(= key SDLK_SPACE)
                (when (= m MODE-PARTICLES)
                  (reset-particles!))
                (values run? m)]
               [else (values run? m)])]

            [_ (values run? m)])))

      (when still-running?
        ;; Draw based on mode
        (case new-mode
          [(1) (draw-triangles-demo renderer)]
          [(2) (draw-indexed-demo renderer frame)]
          [(3) (draw-particles-demo renderer)])

        ;; Draw mode selector at bottom
        (set-draw-color! renderer 150 150 150)
        (render-debug-text! renderer 10 (- window-height 15)
                             "Press 1=Triangles, 2=Indexed, 3=Particles | ESC=Quit")

        (render-present! renderer)
        (delay! 16)

        (loop still-running? new-mode (+ frame 1)))))

  ;; Clean up
  (renderer-destroy! renderer)
  (window-destroy! window))

;; Run the example when executed directly
(module+ main
  (main))
