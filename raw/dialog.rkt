#lang racket/base

;; SDL3 Dialog Functions
;;
;; Functions for file dialogs and message boxes.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide ;; Message Box
         SDL-ShowSimpleMessageBox
         SDL-ShowMessageBox
         ;; File Dialogs
         SDL-ShowOpenFileDialog
         SDL-ShowSaveFileDialog
         SDL-ShowOpenFolderDialog)

;; ============================================================================
;; Message Box
;; ============================================================================

;; SDL_ShowSimpleMessageBox: Display a simple modal message box
;; flags: SDL_MessageBoxFlags (ERROR, WARNING, or INFORMATION)
;; title: UTF-8 title text
;; message: UTF-8 message text
;; window: parent window, or NULL for no parent
;; Returns: true on success, false on failure
(define-sdl SDL-ShowSimpleMessageBox
  (_fun _SDL_MessageBoxFlags _string/utf-8 _string/utf-8 _SDL_Window-pointer/null
        -> _sdl-bool)
  #:c-id SDL_ShowSimpleMessageBox)

;; SDL_ShowMessageBox: Create a modal message box with custom buttons
;; messageboxdata: pointer to SDL_MessageBoxData structure
;; buttonid: pointer to receive the ID of the clicked button
;; Returns: true on success, false on failure
(define-sdl SDL-ShowMessageBox
  (_fun _SDL_MessageBoxData-pointer
        (buttonid : (_ptr o _int))
        -> (result : _sdl-bool)
        -> (values result buttonid))
  #:c-id SDL_ShowMessageBox)

;; ============================================================================
;; File Dialogs
;; ============================================================================

;; SDL_ShowOpenFileDialog: Display a dialog to let the user select a file
;; callback: function called when user selects file(s) or cancels
;; userdata: optional data passed to callback
;; window: parent window for modal behavior (can be NULL)
;; filters: array of SDL_DialogFileFilter (can be NULL)
;; nfilters: number of filters
;; default_location: starting folder/file (can be NULL)
;; allow_many: if true, user can select multiple files
;; Note: This is async - returns immediately, callback called later
(define-sdl SDL-ShowOpenFileDialog
  (_fun _SDL_DialogFileCallback
        _pointer                          ; userdata
        _SDL_Window-pointer/null          ; window
        _SDL_DialogFileFilter-pointer/null ; filters
        _int                              ; nfilters
        _string/utf-8                     ; default_location (can be NULL)
        _stdbool                          ; allow_many
        -> _void)
  #:c-id SDL_ShowOpenFileDialog)

;; SDL_ShowSaveFileDialog: Display a dialog to let the user choose a save location
;; callback: function called when user selects file or cancels
;; userdata: optional data passed to callback
;; window: parent window for modal behavior (can be NULL)
;; filters: array of SDL_DialogFileFilter (can be NULL)
;; nfilters: number of filters
;; default_location: starting folder/file (can be NULL)
;; Note: This is async - returns immediately, callback called later
(define-sdl SDL-ShowSaveFileDialog
  (_fun _SDL_DialogFileCallback
        _pointer                          ; userdata
        _SDL_Window-pointer/null          ; window
        _SDL_DialogFileFilter-pointer/null ; filters
        _int                              ; nfilters
        _string/utf-8                     ; default_location (can be NULL)
        -> _void)
  #:c-id SDL_ShowSaveFileDialog)

;; SDL_ShowOpenFolderDialog: Display a dialog to let the user select a folder
;; callback: function called when user selects folder(s) or cancels
;; userdata: optional data passed to callback
;; window: parent window for modal behavior (can be NULL)
;; default_location: starting folder (can be NULL)
;; allow_many: if true, user can select multiple folders
;; Note: This is async - returns immediately, callback called later
(define-sdl SDL-ShowOpenFolderDialog
  (_fun _SDL_DialogFileCallback
        _pointer                          ; userdata
        _SDL_Window-pointer/null          ; window
        _string/utf-8                     ; default_location (can be NULL)
        _stdbool                          ; allow_many
        -> _void)
  #:c-id SDL_ShowOpenFolderDialog)
