#lang racket/base

;; Tetris Clone - SDL3 Demo
;;
;; A classic falling-block puzzle game demonstrating:
;; - Discrete grid-based game logic
;; - Time-based piece dropping with delta-time
;; - Efficient batch rendering with fill-rects!
;; - Ghost piece preview
;; - Functional game state management
;;
;; Controls:
;;   Left/Right - Move piece
;;   Down - Soft drop (faster falling)
;;   Up or X - Rotate clockwise
;;   Z - Rotate counter-clockwise
;;   Space - Hard drop (instant drop)
;;   P - Pause/unpause
;;   Escape - Quit

(require racket/match
         racket/vector
         sdl3)

;; ============================================================================
;; Constants
;; ============================================================================

(define WINDOW-WIDTH 500)
(define WINDOW-HEIGHT 600)
(define WINDOW-TITLE "SDL3 Tetris")

;; Board dimensions (standard Tetris)
(define BOARD-WIDTH 10)
(define BOARD-HEIGHT 20)
(define CELL-SIZE 28)

;; Board position on screen
(define BOARD-X 20)
(define BOARD-Y 20)

;; Preview area position
(define PREVIEW-X (+ BOARD-X (* BOARD-WIDTH CELL-SIZE) 30))
(define PREVIEW-Y 60)

;; Drop timing (seconds)
(define INITIAL-DROP-INTERVAL 0.8)
(define MIN-DROP-INTERVAL 0.05)
(define SOFT-DROP-INTERVAL 0.05)
(define LOCK-DELAY 0.5)  ; time before piece locks after landing

;; Scoring
(define POINTS-PER-LINE '#(0 100 300 500 800))  ; 0, 1, 2, 3, 4 lines
(define LINES-PER-LEVEL 10)

;; Colors for pieces (I, O, T, S, Z, J, L) - indices 1-7, 0 = empty
(define PIECE-COLORS
  (vector '(40 40 50)      ; 0: empty/background
          '(0 240 240)     ; 1: I - cyan
          '(240 240 0)     ; 2: O - yellow
          '(160 0 240)     ; 3: T - purple
          '(0 240 0)       ; 4: S - green
          '(240 0 0)       ; 5: Z - red
          '(0 0 240)       ; 6: J - blue
          '(240 160 0)))   ; 7: L - orange

(define GHOST-ALPHA 80)
(define GRID-COLOR '(60 60 70))
(define BORDER-COLOR '(100 100 120))
(define TEXT-COLOR '(200 200 200))

;; ============================================================================
;; Piece Definitions
;; ============================================================================

;; Each piece is defined as a list of 4 rotations
;; Each rotation is a list of (col . row) offsets from the piece center
;; Using SRS (Super Rotation System) style coordinates

(define PIECES
  (vector
   ;; I piece (index 1)
   (vector '((0 . 1) (1 . 1) (2 . 1) (3 . 1))    ; 0°
           '((2 . 0) (2 . 1) (2 . 2) (2 . 3))    ; 90°
           '((0 . 2) (1 . 2) (2 . 2) (3 . 2))    ; 180°
           '((1 . 0) (1 . 1) (1 . 2) (1 . 3)))   ; 270°

   ;; O piece (index 2)
   (vector '((1 . 0) (2 . 0) (1 . 1) (2 . 1))    ; all rotations same
           '((1 . 0) (2 . 0) (1 . 1) (2 . 1))
           '((1 . 0) (2 . 0) (1 . 1) (2 . 1))
           '((1 . 0) (2 . 0) (1 . 1) (2 . 1)))

   ;; T piece (index 3)
   (vector '((1 . 0) (0 . 1) (1 . 1) (2 . 1))    ; 0°
           '((1 . 0) (1 . 1) (2 . 1) (1 . 2))    ; 90°
           '((0 . 1) (1 . 1) (2 . 1) (1 . 2))    ; 180°
           '((1 . 0) (0 . 1) (1 . 1) (1 . 2)))   ; 270°

   ;; S piece (index 4)
   (vector '((1 . 0) (2 . 0) (0 . 1) (1 . 1))    ; 0°
           '((1 . 0) (1 . 1) (2 . 1) (2 . 2))    ; 90°
           '((1 . 1) (2 . 1) (0 . 2) (1 . 2))    ; 180°
           '((0 . 0) (0 . 1) (1 . 1) (1 . 2)))   ; 270°

   ;; Z piece (index 5)
   (vector '((0 . 0) (1 . 0) (1 . 1) (2 . 1))    ; 0°
           '((2 . 0) (1 . 1) (2 . 1) (1 . 2))    ; 90°
           '((0 . 1) (1 . 1) (1 . 2) (2 . 2))    ; 180°
           '((1 . 0) (0 . 1) (1 . 1) (0 . 2)))   ; 270°

   ;; J piece (index 6)
   (vector '((0 . 0) (0 . 1) (1 . 1) (2 . 1))    ; 0°
           '((1 . 0) (2 . 0) (1 . 1) (1 . 2))    ; 90°
           '((0 . 1) (1 . 1) (2 . 1) (2 . 2))    ; 180°
           '((1 . 0) (1 . 1) (0 . 2) (1 . 2)))   ; 270°

   ;; L piece (index 7)
   (vector '((2 . 0) (0 . 1) (1 . 1) (2 . 1))    ; 0°
           '((1 . 0) (1 . 1) (1 . 2) (2 . 2))    ; 90°
           '((0 . 1) (1 . 1) (2 . 1) (0 . 2))    ; 180°
           '((0 . 0) (1 . 0) (1 . 1) (1 . 2))))) ; 270°

;; Get piece cells for a given piece type (1-7) and rotation (0-3)
(define (get-piece-cells piece-type rotation)
  (vector-ref (vector-ref PIECES (sub1 piece-type)) rotation))

;; ============================================================================
;; Game State
;; ============================================================================

(struct game-state
  (board              ; vector of BOARD-WIDTH * BOARD-HEIGHT cells (0 = empty, 1-7 = piece color)
   current-piece      ; piece type (1-7)
   current-rotation   ; rotation (0-3)
   piece-x piece-y    ; piece position (grid coords, top-left of bounding box)
   next-piece         ; next piece type (1-7)
   score
   lines              ; total lines cleared
   level
   drop-timer         ; time until next automatic drop
   lock-timer         ; time until piece locks (when on ground)
   game-over?
   paused?)
  #:transparent)

;; Create empty board
(define (make-board)
  (make-vector (* BOARD-WIDTH BOARD-HEIGHT) 0))

;; Board accessors
(define (board-ref board col row)
  (if (and (>= col 0) (< col BOARD-WIDTH)
           (>= row 0) (< row BOARD-HEIGHT))
      (vector-ref board (+ (* row BOARD-WIDTH) col))
      1))  ; out of bounds = solid

(define (board-set board col row value)
  (define new-board (vector-copy board))
  (when (and (>= col 0) (< col BOARD-WIDTH)
             (>= row 0) (< row BOARD-HEIGHT))
    (vector-set! new-board (+ (* row BOARD-WIDTH) col) value))
  new-board)

;; Get random piece type (1-7)
(define (random-piece)
  (add1 (random 7)))

;; Calculate drop interval for current level
(define (drop-interval-for-level level)
  (max MIN-DROP-INTERVAL
       (- INITIAL-DROP-INTERVAL (* (sub1 level) 0.07))))

;; Create initial game state
(define (make-initial-state)
  (game-state (make-board)
              (random-piece)     ; current piece
              0                  ; rotation
              3                  ; piece-x (centered)
              0                  ; piece-y (top)
              (random-piece)     ; next piece
              0                  ; score
              0                  ; lines
              1                  ; level
              INITIAL-DROP-INTERVAL
              #f                 ; no lock timer initially
              #f                 ; not game over
              #f))               ; not paused

;; ============================================================================
;; Collision Detection
;; ============================================================================

;; Check if piece fits at given position
(define (piece-fits? board piece-type rotation px py)
  (define cells (get-piece-cells piece-type rotation))
  (for/and ([cell (in-list cells)])
    (define col (+ px (car cell)))
    (define row (+ py (cdr cell)))
    (and (>= col 0) (< col BOARD-WIDTH)
         (< row BOARD-HEIGHT)  ; can be above board
         (or (< row 0)         ; above board is ok
             (= 0 (board-ref board col row))))))

;; Find where piece would land (for ghost piece)
(define (find-drop-position board piece-type rotation px py)
  (let loop ([y py])
    (if (piece-fits? board piece-type rotation px (add1 y))
        (loop (add1 y))
        y)))

;; ============================================================================
;; Piece Movement
;; ============================================================================

;; Try to move piece, return new state or #f if blocked
(define (try-move state dx dy)
  (define new-x (+ (game-state-piece-x state) dx))
  (define new-y (+ (game-state-piece-y state) dy))
  (if (piece-fits? (game-state-board state)
                   (game-state-current-piece state)
                   (game-state-current-rotation state)
                   new-x new-y)
      (struct-copy game-state state
                   [piece-x new-x]
                   [piece-y new-y]
                   [lock-timer #f])  ; reset lock timer on successful move
      #f))

;; Try to rotate piece with wall kicks
(define (try-rotate state direction)  ; direction: 1 = CW, -1 = CCW
  (define new-rotation (modulo (+ (game-state-current-rotation state) direction) 4))
  (define board (game-state-board state))
  (define piece (game-state-current-piece state))
  (define px (game-state-piece-x state))
  (define py (game-state-piece-y state))

  ;; Try basic rotation first, then wall kicks
  (define kicks '((0 . 0) (-1 . 0) (1 . 0) (0 . -1) (-1 . -1) (1 . -1) (-2 . 0) (2 . 0)))

  (let loop ([kicks kicks])
    (if (null? kicks)
        #f
        (let* ([kick (car kicks)]
               [new-x (+ px (car kick))]
               [new-y (+ py (cdr kick))])
          (if (piece-fits? board piece new-rotation new-x new-y)
              (struct-copy game-state state
                           [current-rotation new-rotation]
                           [piece-x new-x]
                           [piece-y new-y]
                           [lock-timer #f])
              (loop (cdr kicks)))))))

;; ============================================================================
;; Line Clearing
;; ============================================================================

;; Check if a row is complete
(define (row-complete? board row)
  (for/and ([col (in-range BOARD-WIDTH)])
    (positive? (board-ref board col row))))

;; Clear completed lines and return (new-board . lines-cleared)
(define (clear-lines board)
  (define complete-rows
    (for/list ([row (in-range BOARD-HEIGHT)]
               #:when (row-complete? board row))
      row))

  (if (null? complete-rows)
      (cons board 0)
      ;; Build new board by copying non-complete rows
      (let* ([kept-rows (for/list ([row (in-range BOARD-HEIGHT)]
                                    #:unless (member row complete-rows))
                          row)]
             [new-board (make-board)]
             [num-cleared (length complete-rows)])
        ;; Copy kept rows to bottom of new board
        (for ([old-row (in-list kept-rows)]
              [new-row (in-naturals num-cleared)])
          (for ([col (in-range BOARD-WIDTH)])
            (vector-set! new-board
                         (+ (* new-row BOARD-WIDTH) col)
                         (board-ref board col old-row))))
        (cons new-board num-cleared))))

;; ============================================================================
;; Piece Locking and Spawning
;; ============================================================================

;; Lock piece into board and spawn new piece
(define (lock-piece state)
  (define board (game-state-board state))
  (define piece (game-state-current-piece state))
  (define rotation (game-state-current-rotation state))
  (define px (game-state-piece-x state))
  (define py (game-state-piece-y state))

  ;; Add piece to board
  (define cells (get-piece-cells piece rotation))
  (define new-board
    (for/fold ([b board])
              ([cell (in-list cells)])
      (board-set b (+ px (car cell)) (+ py (cdr cell)) piece)))

  ;; Clear lines
  (define-values (cleared-board lines-cleared)
    (let ([result (clear-lines new-board)])
      (values (car result) (cdr result))))

  ;; Update score and level
  (define new-lines (+ (game-state-lines state) lines-cleared))
  (define new-level (add1 (quotient new-lines LINES-PER-LEVEL)))
  (define new-score (+ (game-state-score state)
                       (* (vector-ref POINTS-PER-LINE lines-cleared)
                          new-level)))

  ;; Spawn new piece
  (define next-piece (game-state-next-piece state))
  (define spawn-x 3)
  (define spawn-y 0)

  ;; Check if new piece fits (game over if not)
  (define game-over? (not (piece-fits? cleared-board next-piece 0 spawn-x spawn-y)))

  (struct-copy game-state state
               [board cleared-board]
               [current-piece next-piece]
               [current-rotation 0]
               [piece-x spawn-x]
               [piece-y spawn-y]
               [next-piece (random-piece)]
               [score new-score]
               [lines new-lines]
               [level new-level]
               [drop-timer (drop-interval-for-level new-level)]
               [lock-timer #f]
               [game-over? game-over?]))

;; Hard drop - instantly drop and lock piece
(define (hard-drop state)
  (define drop-y (find-drop-position (game-state-board state)
                                     (game-state-current-piece state)
                                     (game-state-current-rotation state)
                                     (game-state-piece-x state)
                                     (game-state-piece-y state)))
  (define dropped-state (struct-copy game-state state [piece-y drop-y]))
  (lock-piece dropped-state))

;; ============================================================================
;; Game Update
;; ============================================================================

(define (update-game state dt #:soft-drop? [soft-drop? #f])
  (cond
    [(game-state-paused? state) state]
    [(game-state-game-over? state) state]
    [else
     ;; Check if piece is on the ground (can't move down)
     (define on-ground?
       (not (piece-fits? (game-state-board state)
                         (game-state-current-piece state)
                         (game-state-current-rotation state)
                         (game-state-piece-x state)
                         (add1 (game-state-piece-y state)))))

     (cond
       ;; Piece is on ground - handle lock delay
       ;; When soft-dropping, lock immediately
       [on-ground?
        (if soft-drop?
            ;; Soft drop locks immediately when hitting ground
            (lock-piece state)
            ;; Normal lock delay
            (let* ([lock-timer (or (game-state-lock-timer state) LOCK-DELAY)]
                   [new-lock-timer (- lock-timer dt)])
              (if (<= new-lock-timer 0)
                  (lock-piece state)
                  (struct-copy game-state state
                               [lock-timer new-lock-timer]))))]

       ;; Piece is in the air - handle dropping
       [else
        (define new-drop-timer (- (game-state-drop-timer state) dt))
        (if (<= new-drop-timer 0)
            ;; Time to drop
            (let ([moved (try-move state 0 1)])
              (struct-copy game-state (or moved state)
                           [drop-timer (drop-interval-for-level
                                        (game-state-level state))]
                           [lock-timer #f]))
            ;; Just update timer
            (struct-copy game-state state
                         [drop-timer new-drop-timer]))])]))

;; ============================================================================
;; Rendering
;; ============================================================================

(define (render-game! renderer state)
  ;; Clear background
  (set-draw-color! renderer 30 30 40)
  (render-clear! renderer)

  ;; Draw board border
  (set-draw-color! renderer 100 100 120)
  (draw-rect! renderer
              (- BOARD-X 2) (- BOARD-Y 2)
              (+ (* BOARD-WIDTH CELL-SIZE) 4)
              (+ (* BOARD-HEIGHT CELL-SIZE) 4))

  ;; Draw board background
  (set-draw-color! renderer 40 40 50)
  (fill-rect! renderer BOARD-X BOARD-Y
              (* BOARD-WIDTH CELL-SIZE)
              (* BOARD-HEIGHT CELL-SIZE))

  ;; Draw grid lines
  (set-draw-color! renderer 50 50 60)
  (for ([col (in-range (add1 BOARD-WIDTH))])
    (define x (+ BOARD-X (* col CELL-SIZE)))
    (draw-line! renderer x BOARD-Y x (+ BOARD-Y (* BOARD-HEIGHT CELL-SIZE))))
  (for ([row (in-range (add1 BOARD-HEIGHT))])
    (define y (+ BOARD-Y (* row CELL-SIZE)))
    (draw-line! renderer BOARD-X y (+ BOARD-X (* BOARD-WIDTH CELL-SIZE)) y))

  ;; Draw board cells
  (for* ([row (in-range BOARD-HEIGHT)]
         [col (in-range BOARD-WIDTH)])
    (define cell (board-ref (game-state-board state) col row))
    (when (positive? cell)
      (define color (vector-ref PIECE-COLORS cell))
      (apply set-draw-color! renderer color)
      (fill-rect! renderer
                  (+ BOARD-X (* col CELL-SIZE) 1)
                  (+ BOARD-Y (* row CELL-SIZE) 1)
                  (- CELL-SIZE 2)
                  (- CELL-SIZE 2))))

  ;; Draw ghost piece
  (unless (game-state-game-over? state)
    (define ghost-y (find-drop-position (game-state-board state)
                                        (game-state-current-piece state)
                                        (game-state-current-rotation state)
                                        (game-state-piece-x state)
                                        (game-state-piece-y state)))
    (define cells (get-piece-cells (game-state-current-piece state)
                                   (game-state-current-rotation state)))
    (define color (vector-ref PIECE-COLORS (game-state-current-piece state)))
    (set-draw-color! renderer (car color) (cadr color) (caddr color) GHOST-ALPHA)
    (for ([cell (in-list cells)])
      (define col (+ (game-state-piece-x state) (car cell)))
      (define row (+ ghost-y (cdr cell)))
      (when (>= row 0)
        (fill-rect! renderer
                    (+ BOARD-X (* col CELL-SIZE) 1)
                    (+ BOARD-Y (* row CELL-SIZE) 1)
                    (- CELL-SIZE 2)
                    (- CELL-SIZE 2)))))

  ;; Draw current piece
  (unless (game-state-game-over? state)
    (define cells (get-piece-cells (game-state-current-piece state)
                                   (game-state-current-rotation state)))
    (define color (vector-ref PIECE-COLORS (game-state-current-piece state)))
    (apply set-draw-color! renderer color)
    (for ([cell (in-list cells)])
      (define col (+ (game-state-piece-x state) (car cell)))
      (define row (+ (game-state-piece-y state) (cdr cell)))
      (when (>= row 0)
        (fill-rect! renderer
                    (+ BOARD-X (* col CELL-SIZE) 1)
                    (+ BOARD-Y (* row CELL-SIZE) 1)
                    (- CELL-SIZE 2)
                    (- CELL-SIZE 2)))))

  ;; Draw preview box
  (set-draw-color! renderer 100 100 120)
  (draw-rect! renderer (- PREVIEW-X 2) (- PREVIEW-Y 2) 104 104)
  (set-draw-color! renderer 40 40 50)
  (fill-rect! renderer PREVIEW-X PREVIEW-Y 100 100)

  ;; Draw next piece in preview
  (define next-cells (get-piece-cells (game-state-next-piece state) 0))
  (define next-color (vector-ref PIECE-COLORS (game-state-next-piece state)))
  (apply set-draw-color! renderer next-color)
  (for ([cell (in-list next-cells)])
    (define col (car cell))
    (define row (cdr cell))
    (fill-rect! renderer
                (+ PREVIEW-X (* col 22) 10)
                (+ PREVIEW-Y (* row 22) 10)
                20 20))

  ;; Draw labels and stats
  (set-draw-color! renderer 200 200 200)
  (render-debug-text! renderer PREVIEW-X 40 "NEXT")

  (render-debug-text! renderer PREVIEW-X 180 "SCORE")
  (render-debug-text! renderer PREVIEW-X 200
                      (number->string (game-state-score state)))

  (render-debug-text! renderer PREVIEW-X 240 "LINES")
  (render-debug-text! renderer PREVIEW-X 260
                      (number->string (game-state-lines state)))

  (render-debug-text! renderer PREVIEW-X 300 "LEVEL")
  (render-debug-text! renderer PREVIEW-X 320
                      (number->string (game-state-level state)))

  ;; Draw controls help
  (set-draw-color! renderer 120 120 140)
  (render-debug-text! renderer PREVIEW-X 400 "CONTROLS")
  (render-debug-text! renderer PREVIEW-X 420 "Arrows:Move")
  (render-debug-text! renderer PREVIEW-X 440 "Up/X: Rotate")
  (render-debug-text! renderer PREVIEW-X 460 "Space: Drop")
  (render-debug-text! renderer PREVIEW-X 480 "P: Pause")

  ;; Draw pause overlay
  (when (game-state-paused? state)
    (set-draw-color! renderer 0 0 0 180)
    (fill-rect! renderer 0 0 WINDOW-WIDTH WINDOW-HEIGHT)
    (set-draw-color! renderer 255 255 255)
    (render-debug-text! renderer 200 280 "PAUSED")
    (render-debug-text! renderer 160 310 "Press P to continue"))

  ;; Draw game over overlay
  (when (game-state-game-over? state)
    (set-draw-color! renderer 0 0 0 200)
    (fill-rect! renderer 0 0 WINDOW-WIDTH WINDOW-HEIGHT)
    (set-draw-color! renderer 255 100 100)
    (render-debug-text! renderer 180 260 "GAME OVER")
    (set-draw-color! renderer 255 255 255)
    (render-debug-text! renderer 150 300
                        (format "Final Score: ~a" (game-state-score state)))
    (render-debug-text! renderer 130 340 "Press SPACE to play again"))

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
        (define dt (min 0.1 (/ (- now last-ticks) 1000.0)))

        ;; Get keyboard state for continuous input (soft drop)
        (define kbd (get-keyboard-state))
        (define soft-dropping? (and (kbd 'down)
                                    (not (game-state-paused? state))
                                    (not (game-state-game-over? state))))

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
                 [else
                  (values run? (hard-drop st))])]

              [(key-event 'down 'left _ _ _)
               (if (or (game-state-paused? st) (game-state-game-over? st))
                   (values run? st)
                   (values run? (or (try-move st -1 0) st)))]

              [(key-event 'down 'right _ _ _)
               (if (or (game-state-paused? st) (game-state-game-over? st))
                   (values run? st)
                   (values run? (or (try-move st 1 0) st)))]

              [(key-event 'down key _ _ _)
               #:when (or (eq? key 'up) (eq? key 'x))
               (if (or (game-state-paused? st) (game-state-game-over? st))
                   (values run? st)
                   (values run? (or (try-rotate st 1) st)))]

              [(key-event 'down 'z _ _ _)
               (if (or (game-state-paused? st) (game-state-game-over? st))
                   (values run? st)
                   (values run? (or (try-rotate st -1) st)))]

              [_ (values run? st)])))

        (when running?
          ;; Apply soft drop speed if holding down arrow
          (define state-with-drop-speed
            (if soft-dropping?
                (struct-copy game-state new-state
                             [drop-timer (min (game-state-drop-timer new-state)
                                             SOFT-DROP-INTERVAL)])
                new-state))

          ;; Update game state
          (define updated-state (update-game state-with-drop-speed dt
                                             #:soft-drop? soft-dropping?))

          ;; Render
          (render-game! renderer updated-state)

          ;; Small delay to prevent burning CPU
          (delay! 1)

          (loop updated-state now))))))

;; Run when executed directly
(module+ main
  (main))
