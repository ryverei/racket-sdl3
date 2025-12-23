#lang racket/base

;; Breakout Clone - SDL3 Demo
;;
;; A classic brick-breaking game demonstrating:
;; - Time-based physics with delta-time
;; - Efficient collision detection using SDL3 rect functions
;; - State-polling keyboard input for smooth paddle control
;; - Functional game state management
;;
;; Controls:
;;   Left/Right or A/D - Move paddle
;;   Space - Launch ball / Start new game
;;   P - Pause/unpause
;;   Escape - Quit

(require racket/match
         racket/math
         racket/vector
         sdl3)

;; ============================================================================
;; Constants
;; ============================================================================

(define WINDOW-WIDTH 800)
(define WINDOW-HEIGHT 600)
(define WINDOW-TITLE "SDL3 Breakout")

;; Paddle
(define PADDLE-WIDTH 100.0)
(define PADDLE-HEIGHT 15.0)
(define PADDLE-Y (- WINDOW-HEIGHT 50.0))
(define PADDLE-SPEED 500.0)  ; pixels per second

;; Ball
(define BALL-SIZE 12.0)
(define BALL-INITIAL-SPEED 350.0)  ; pixels per second
(define BALL-MAX-SPEED 600.0)
(define BALL-SPEED-INCREMENT 10.0)  ; speed increase per brick hit

;; Bricks
(define BRICK-ROWS 6)
(define BRICK-COLS 10)
(define BRICK-WIDTH 70.0)
(define BRICK-HEIGHT 25.0)
(define BRICK-PADDING 5.0)
(define BRICK-TOP-OFFSET 60.0)
(define BRICK-LEFT-OFFSET
  (/ (- WINDOW-WIDTH
        (+ (* BRICK-COLS BRICK-WIDTH)
           (* (sub1 BRICK-COLS) BRICK-PADDING)))
     2.0))

;; Colors (r g b) for each row
(define BRICK-COLORS
  (vector '(220 50 50)    ; Red
          '(220 140 50)   ; Orange
          '(220 220 50)   ; Yellow
          '(50 220 50)    ; Green
          '(50 150 220)   ; Blue
          '(150 50 220))) ; Purple

(define BACKGROUND-COLOR '(20 20 30))
(define PADDLE-COLOR '(200 200 220))
(define BALL-COLOR '(255 255 255))
(define TEXT-COLOR '(180 180 180))

;; ============================================================================
;; Game State
;; ============================================================================

;; Brick: position, size, color, and whether destroyed
(struct brick (x y w h color destroyed?) #:transparent)

;; Main game state
(struct game-state
  (paddle-x                    ; paddle center x
   ball-x ball-y               ; ball center position
   ball-vx ball-vy             ; ball velocity
   ball-speed                  ; current ball speed magnitude
   ball-attached?              ; ball stuck to paddle?
   bricks                      ; vector of brick structs
   lives score
   game-over? won?
   paused?)
  #:transparent)

;; ============================================================================
;; Initialization
;; ============================================================================

;; Create the initial brick grid
(define (make-bricks)
  (for*/vector ([row (in-range BRICK-ROWS)]
                [col (in-range BRICK-COLS)])
    (define x (+ BRICK-LEFT-OFFSET (* col (+ BRICK-WIDTH BRICK-PADDING))))
    (define y (+ BRICK-TOP-OFFSET (* row (+ BRICK-HEIGHT BRICK-PADDING))))
    (define color (vector-ref BRICK-COLORS row))
    (brick x y BRICK-WIDTH BRICK-HEIGHT color #f)))

;; Create initial game state
(define (make-initial-state)
  (define paddle-x (/ WINDOW-WIDTH 2.0))
  (game-state paddle-x
              paddle-x (- PADDLE-Y BALL-SIZE)  ; ball on paddle
              0.0 0.0                           ; no velocity yet
              BALL-INITIAL-SPEED
              #t                                ; attached to paddle
              (make-bricks)
              3 0                               ; 3 lives, 0 score
              #f #f                             ; not over, not won
              #f))                              ; not paused

;; Reset ball to paddle (after losing a life)
(define (reset-ball state)
  (struct-copy game-state state
               [ball-x (game-state-paddle-x state)]
               [ball-y (- PADDLE-Y BALL-SIZE)]
               [ball-vx 0.0]
               [ball-vy 0.0]
               [ball-attached? #t]))

;; ============================================================================
;; Physics and Collision
;; ============================================================================

;; Launch ball from paddle at an angle
(define (launch-ball state)
  (if (game-state-ball-attached? state)
      (let* ([speed (game-state-ball-speed state)]
             ;; Launch at 60-degree angle upward, random left or right
             [angle (+ (/ pi 3) (* (random) (/ pi 6)))]  ; 60-75 degrees
             [direction (if (zero? (random 2)) -1 1)]
             [vx (* direction speed (cos angle))]
             [vy (- (* speed (sin angle)))])  ; negative = upward
        (struct-copy game-state state
                     [ball-vx vx]
                     [ball-vy vy]
                     [ball-attached? #f]))
      state))

;; Move paddle based on keyboard state
(define (update-paddle state kbd dt)
  (define dx
    (cond
      [(or (kbd 'left) (kbd 'a)) (- (* PADDLE-SPEED dt))]
      [(or (kbd 'right) (kbd 'd)) (* PADDLE-SPEED dt)]
      [else 0.0]))
  (define new-x (+ (game-state-paddle-x state) dx))
  ;; Clamp to screen bounds
  (define clamped-x
    (max (/ PADDLE-WIDTH 2.0)
         (min (- WINDOW-WIDTH (/ PADDLE-WIDTH 2.0)) new-x)))
  ;; If ball is attached, move it with paddle
  (if (game-state-ball-attached? state)
      (struct-copy game-state state
                   [paddle-x clamped-x]
                   [ball-x clamped-x])
      (struct-copy game-state state
                   [paddle-x clamped-x])))

;; Move ball and handle wall collisions
(define (update-ball-position state dt)
  (if (game-state-ball-attached? state)
      state
      (let* ([x (game-state-ball-x state)]
             [y (game-state-ball-y state)]
             [vx (game-state-ball-vx state)]
             [vy (game-state-ball-vy state)]
             [half-size (/ BALL-SIZE 2.0)]
             ;; New position
             [new-x (+ x (* vx dt))]
             [new-y (+ y (* vy dt))]
             ;; Wall collisions
             [hit-left? (< new-x half-size)]
             [hit-right? (> new-x (- WINDOW-WIDTH half-size))]
             [hit-top? (< new-y half-size)]
             [hit-bottom? (> new-y WINDOW-HEIGHT)]
             ;; Adjust position and velocity for wall hits
             [final-x (cond [hit-left? half-size]
                            [hit-right? (- WINDOW-WIDTH half-size)]
                            [else new-x])]
             [final-y (if hit-top? half-size new-y)]
             [final-vx (if (or hit-left? hit-right?) (- vx) vx)]
             [final-vy (if hit-top? (- vy) vy)])
        ;; Check if ball fell off bottom
        (if hit-bottom?
            (let ([new-lives (sub1 (game-state-lives state))])
              (if (<= new-lives 0)
                  (struct-copy game-state state
                               [lives 0]
                               [game-over? #t])
                  (reset-ball (struct-copy game-state state
                                           [lives new-lives]))))
            (struct-copy game-state state
                         [ball-x final-x]
                         [ball-y final-y]
                         [ball-vx final-vx]
                         [ball-vy final-vy])))))

;; Check and handle paddle collision
(define (check-paddle-collision state)
  (if (game-state-ball-attached? state)
      state
      (let* ([bx (game-state-ball-x state)]
             [by (game-state-ball-y state)]
             [vy (game-state-ball-vy state)]
             [half-ball (/ BALL-SIZE 2.0)]
             [px (game-state-paddle-x state)]
             [half-paddle (/ PADDLE-WIDTH 2.0)]
             ;; Ball rect
             [ball-left (- bx half-ball)]
             [ball-right (+ bx half-ball)]
             [ball-bottom (+ by half-ball)]
             ;; Paddle rect
             [paddle-left (- px half-paddle)]
             [paddle-right (+ px half-paddle)]
             [paddle-top PADDLE-Y])
        ;; Check if ball is hitting paddle (only when moving down)
        (if (and (> vy 0)
                 (> ball-bottom paddle-top)
                 (< by (+ PADDLE-Y PADDLE-HEIGHT))
                 (> ball-right paddle-left)
                 (< ball-left paddle-right))
            ;; Calculate bounce angle based on hit position
            (let* ([hit-pos (/ (- bx paddle-left) PADDLE-WIDTH)]  ; 0.0 to 1.0
                   ;; Map to angle: -60° at left edge, +60° at right edge
                   [angle (* (- hit-pos 0.5) (/ (* 2 pi) 3))]  ; -60° to +60°
                   [speed (game-state-ball-speed state)]
                   [new-vx (* speed (sin angle))]
                   [new-vy (- (* speed (cos angle)))]  ; always upward
                   ;; Ensure ball is above paddle
                   [new-y (- paddle-top half-ball 1)])
              (struct-copy game-state state
                           [ball-y new-y]
                           [ball-vx new-vx]
                           [ball-vy new-vy]))
            state))))

;; Check brick collisions - returns updated state
(define (check-brick-collisions state)
  (if (game-state-ball-attached? state)
      state
      (let* ([bx (game-state-ball-x state)]
             [by (game-state-ball-y state)]
             [vx (game-state-ball-vx state)]
             [vy (game-state-ball-vy state)]
             [half-ball (/ BALL-SIZE 2.0)]
             [bricks (game-state-bricks state)]
             [ball-rect (make-frect (- bx half-ball) (- by half-ball)
                                    BALL-SIZE BALL-SIZE)])
        ;; Find first brick collision
        (let loop ([i 0] [state state])
          (if (>= i (vector-length bricks))
              state
              (let ([b (vector-ref bricks i)])
                (if (brick-destroyed? b)
                    (loop (add1 i) state)
                    ;; Check collision with this brick
                    (let ([brick-rect (make-frect (brick-x b) (brick-y b)
                                                  (brick-w b) (brick-h b))])
                      (if (frects-intersect? ball-rect brick-rect)
                          ;; Collision! Determine which side was hit
                          (let* ([brick-cx (+ (brick-x b) (/ (brick-w b) 2))]
                                 [brick-cy (+ (brick-y b) (/ (brick-h b) 2))]
                                 [dx (- bx brick-cx)]
                                 [dy (- by brick-cy)]
                                 ;; Compare overlap on each axis
                                 [overlap-x (- (+ (/ (brick-w b) 2) half-ball) (abs dx))]
                                 [overlap-y (- (+ (/ (brick-h b) 2) half-ball) (abs dy))]
                                 ;; Reflect on axis with smaller overlap
                                 [new-vx (if (< overlap-x overlap-y) (- vx) vx)]
                                 [new-vy (if (>= overlap-x overlap-y) (- vy) vy)]
                                 ;; Mark brick as destroyed
                                 [new-bricks (vector-copy bricks)]
                                 [_ (vector-set! new-bricks i
                                                 (struct-copy brick b [destroyed? #t]))]
                                 ;; Update score and speed
                                 [new-score (+ (game-state-score state) 10)]
                                 [new-speed (min BALL-MAX-SPEED
                                                 (+ (game-state-ball-speed state)
                                                    BALL-SPEED-INCREMENT))])
                            ;; Check if all bricks destroyed
                            (define all-destroyed?
                              (for/and ([b (in-vector new-bricks)])
                                (brick-destroyed? b)))
                            (struct-copy game-state state
                                         [ball-vx new-vx]
                                         [ball-vy new-vy]
                                         [ball-speed new-speed]
                                         [bricks new-bricks]
                                         [score new-score]
                                         [won? all-destroyed?]
                                         [game-over? all-destroyed?]))
                          (loop (add1 i) state))))))))))

;; Main update function
(define (update-game state kbd dt)
  (if (or (game-state-paused? state) (game-state-game-over? state))
      state
      (let* ([s1 (update-paddle state kbd dt)]
             [s2 (update-ball-position s1 dt)]
             [s3 (check-paddle-collision s2)]
             [s4 (check-brick-collisions s3)])
        s4)))

;; ============================================================================
;; Rendering
;; ============================================================================

(define (render-game! renderer state)
  ;; Clear background
  (apply set-draw-color! renderer BACKGROUND-COLOR)
  (render-clear! renderer)

  ;; Draw bricks
  (for ([b (in-vector (game-state-bricks state))])
    (unless (brick-destroyed? b)
      (apply set-draw-color! renderer (brick-color b))
      (fill-rect! renderer (brick-x b) (brick-y b) (brick-w b) (brick-h b))
      ;; Slight highlight on top
      (set-draw-color! renderer 255 255 255 80)
      (fill-rect! renderer (brick-x b) (brick-y b) (brick-w b) 3.0)))

  ;; Draw paddle
  (apply set-draw-color! renderer PADDLE-COLOR)
  (define paddle-left (- (game-state-paddle-x state) (/ PADDLE-WIDTH 2.0)))
  (fill-rect! renderer paddle-left PADDLE-Y PADDLE-WIDTH PADDLE-HEIGHT)

  ;; Draw ball
  (apply set-draw-color! renderer BALL-COLOR)
  (define ball-left (- (game-state-ball-x state) (/ BALL-SIZE 2.0)))
  (define ball-top (- (game-state-ball-y state) (/ BALL-SIZE 2.0)))
  (fill-rect! renderer ball-left ball-top BALL-SIZE BALL-SIZE)

  ;; Draw UI - lives and score
  (apply set-draw-color! renderer TEXT-COLOR)
  (render-debug-text! renderer 10 10
                      (format "Score: ~a" (game-state-score state)))
  (render-debug-text! renderer 10 28
                      (format "Lives: ~a" (game-state-lives state)))

  ;; Draw pause/game over overlay
  (cond
    [(game-state-game-over? state)
     (set-draw-color! renderer 0 0 0 180)
     (fill-rect! renderer 0 0 WINDOW-WIDTH WINDOW-HEIGHT)
     (set-draw-color! renderer 255 255 255)
     (if (game-state-won? state)
         (begin
           (render-debug-text! renderer 340 280 "YOU WIN!")
           (render-debug-text! renderer 280 310
                               (format "Final Score: ~a" (game-state-score state))))
         (begin
           (render-debug-text! renderer 330 280 "GAME OVER")
           (render-debug-text! renderer 280 310
                               (format "Final Score: ~a" (game-state-score state)))))
     (render-debug-text! renderer 290 350 "Press SPACE to play again")]

    [(game-state-paused? state)
     (set-draw-color! renderer 0 0 0 150)
     (fill-rect! renderer 0 0 WINDOW-WIDTH WINDOW-HEIGHT)
     (set-draw-color! renderer 255 255 255)
     (render-debug-text! renderer 360 290 "PAUSED")
     (render-debug-text! renderer 310 320 "Press P to continue")]

    [(game-state-ball-attached? state)
     (set-draw-color! renderer 200 200 200)
     (render-debug-text! renderer 280 (- PADDLE-Y 40)
                         "Press SPACE to launch")])

  (render-present! renderer))

;; ============================================================================
;; Main Loop
;; ============================================================================

(define (main)
  (with-sdl
    (with-window+renderer WINDOW-TITLE WINDOW-WIDTH WINDOW-HEIGHT (window renderer)
      (let loop ([state (make-initial-state)]
                 [last-ticks (current-ticks)])
        (define now (current-ticks))
        (define dt (min 0.05 (/ (- now last-ticks) 1000.0)))  ; cap dt at 50ms

        ;; Get keyboard state for smooth input
        (define kbd (get-keyboard-state))

        ;; Process events
        (define-values (running? new-state)
          (for/fold ([run? #t]
                     [st state])
                    ([ev (in-events)]
                     #:break (not run?))
            (match ev
              [(or (quit-event) (window-event 'close-requested))
               (values #f st)]

              [(key-event 'down 'escape _ _ _)
               (values #f st)]

              [(key-event 'down 'p _ _ _)
               (if (game-state-game-over? st)
                   (values run? st)
                   (values run? (struct-copy game-state st
                                             [paused? (not (game-state-paused? st))])))]

              [(key-event 'down 'space _ _ _)
               (cond
                 [(game-state-game-over? st)
                  (values run? (make-initial-state))]
                 [(game-state-paused? st)
                  (values run? st)]
                 [(game-state-ball-attached? st)
                  (values run? (launch-ball st))]
                 [else (values run? st)])]

              [_ (values run? st)])))

        (when running?
          ;; Update game state
          (define updated-state (update-game new-state kbd dt))

          ;; Render
          (render-game! renderer updated-state)

          ;; Small delay to prevent burning CPU
          (delay! 1)

          (loop updated-state now))))))

;; Run when executed directly
(module+ main
  (main))
