#lang racket/base

;; SDL3 Audio Functions
;;
;; Functions for audio playback and recording.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide ;; Audio - Drivers
         SDL-GetNumAudioDrivers
         SDL-GetAudioDriver
         SDL-GetCurrentAudioDriver
         ;; Audio - Device Enumeration
         SDL-GetAudioPlaybackDevices
         SDL-GetAudioRecordingDevices
         SDL-GetAudioDeviceName
         ;; Audio - Device Control
         SDL-OpenAudioDevice
         SDL-CloseAudioDevice
         SDL-PauseAudioDevice
         SDL-ResumeAudioDevice
         SDL-AudioDevicePaused
         ;; Audio - Streams
         SDL-CreateAudioStream
         SDL-DestroyAudioStream
         SDL-GetAudioStreamFormat
         SDL-SetAudioStreamFormat
         SDL-PutAudioStreamData
         SDL-GetAudioStreamData
         SDL-GetAudioStreamAvailable
         SDL-FlushAudioStream
         SDL-ClearAudioStream
         SDL-BindAudioStream
         SDL-UnbindAudioStream
         ;; Audio - WAV Loading
         SDL-LoadWAV)

;; ============================================================================
;; Audio - Drivers
;; ============================================================================

;; SDL_GetNumAudioDrivers: Get the number of built-in audio drivers
;; Returns: the number of built-in audio drivers
(define-sdl SDL-GetNumAudioDrivers
  (_fun -> _int)
  #:c-id SDL_GetNumAudioDrivers)

;; SDL_GetAudioDriver: Get the name of a built-in audio driver by index
;; index: the index of the audio driver (0 to SDL_GetNumAudioDrivers()-1)
;; Returns: the name of the audio driver, or NULL if invalid index
(define-sdl SDL-GetAudioDriver
  (_fun _int -> _string/utf-8)
  #:c-id SDL_GetAudioDriver)

;; SDL_GetCurrentAudioDriver: Get the name of the current audio driver
;; Returns: the name of the current audio driver, or NULL if not initialized
(define-sdl SDL-GetCurrentAudioDriver
  (_fun -> _string/utf-8)
  #:c-id SDL_GetCurrentAudioDriver)

;; ============================================================================
;; Audio - Device Enumeration
;; ============================================================================

;; SDL_GetAudioPlaybackDevices: Get a list of audio playback devices
;; Returns: (values device-ids count) - array pointer and count, free with SDL_free
;; The returned pointer is a 0-terminated array of SDL_AudioDeviceID values
(define-sdl SDL-GetAudioPlaybackDevices
  (_fun (count : (_ptr o _int))
        -> (result : _pointer)
        -> (values result count))
  #:c-id SDL_GetAudioPlaybackDevices)

;; SDL_GetAudioRecordingDevices: Get a list of audio recording devices
;; Returns: (values device-ids count) - array pointer and count, free with SDL_free
;; The returned pointer is a 0-terminated array of SDL_AudioDeviceID values
(define-sdl SDL-GetAudioRecordingDevices
  (_fun (count : (_ptr o _int))
        -> (result : _pointer)
        -> (values result count))
  #:c-id SDL_GetAudioRecordingDevices)

;; SDL_GetAudioDeviceName: Get the human-readable name of an audio device
;; devid: the device instance ID to query
;; Returns: the name of the audio device, or NULL on failure
(define-sdl SDL-GetAudioDeviceName
  (_fun _SDL_AudioDeviceID -> _string/utf-8)
  #:c-id SDL_GetAudioDeviceName)

;; ============================================================================
;; Audio - Device Control
;; ============================================================================

;; SDL_OpenAudioDevice: Open an audio device for playback or recording
;; devid: device ID, or SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK/RECORDING for default
;; spec: the desired audio format (can be NULL for reasonable defaults)
;; Returns: the device ID on success, or 0 on failure
(define-sdl SDL-OpenAudioDevice
  (_fun _SDL_AudioDeviceID _SDL_AudioSpec-pointer/null -> _SDL_AudioDeviceID)
  #:c-id SDL_OpenAudioDevice)

;; SDL_CloseAudioDevice: Close a previously opened audio device
;; devid: the audio device to close
(define-sdl SDL-CloseAudioDevice
  (_fun _SDL_AudioDeviceID -> _void)
  #:c-id SDL_CloseAudioDevice)

;; SDL_PauseAudioDevice: Pause audio playback on a device
;; devid: the device to pause
;; Returns: true on success, false on failure
(define-sdl SDL-PauseAudioDevice
  (_fun _SDL_AudioDeviceID -> _sdl-bool)
  #:c-id SDL_PauseAudioDevice)

;; SDL_ResumeAudioDevice: Resume audio playback on a device
;; devid: the device to resume
;; Returns: true on success, false on failure
(define-sdl SDL-ResumeAudioDevice
  (_fun _SDL_AudioDeviceID -> _sdl-bool)
  #:c-id SDL_ResumeAudioDevice)

;; SDL_AudioDevicePaused: Check if an audio device is paused
;; devid: the device to query
;; Returns: true if the device is paused, false otherwise
(define-sdl SDL-AudioDevicePaused
  (_fun _SDL_AudioDeviceID -> _stdbool)
  #:c-id SDL_AudioDevicePaused)

;; ============================================================================
;; Audio - Streams
;; ============================================================================

;; SDL_CreateAudioStream: Create an audio stream for format conversion
;; src-spec: the format of the source audio
;; dst-spec: the format of the desired output audio
;; Returns: a new audio stream, or NULL on failure
(define-sdl SDL-CreateAudioStream
  (_fun _SDL_AudioSpec-pointer _SDL_AudioSpec-pointer -> _SDL_AudioStream-pointer/null)
  #:c-id SDL_CreateAudioStream)

;; SDL_DestroyAudioStream: Destroy an audio stream
;; stream: the audio stream to destroy
(define-sdl SDL-DestroyAudioStream
  (_fun _SDL_AudioStream-pointer -> _void)
  #:c-id SDL_DestroyAudioStream)

;; SDL_GetAudioStreamFormat: Get the current input and output formats of an audio stream
;; stream: the audio stream to query
;; src-spec: pointer to receive input format (can be NULL)
;; dst-spec: pointer to receive output format (can be NULL)
;; Returns: true on success, false on failure
(define-sdl SDL-GetAudioStreamFormat
  (_fun _SDL_AudioStream-pointer
        _SDL_AudioSpec-pointer/null
        _SDL_AudioSpec-pointer/null
        -> _sdl-bool)
  #:c-id SDL_GetAudioStreamFormat)

;; SDL_SetAudioStreamFormat: Change the input and output formats of an audio stream
;; stream: the audio stream to modify
;; src-spec: the new input format (can be NULL to leave unchanged)
;; dst-spec: the new output format (can be NULL to leave unchanged)
;; Returns: true on success, false on failure
(define-sdl SDL-SetAudioStreamFormat
  (_fun _SDL_AudioStream-pointer
        _SDL_AudioSpec-pointer/null
        _SDL_AudioSpec-pointer/null
        -> _sdl-bool)
  #:c-id SDL_SetAudioStreamFormat)

;; SDL_PutAudioStreamData: Add data to the stream for processing
;; stream: the audio stream
;; buf: pointer to the audio data to add
;; len: the number of bytes to write
;; Returns: true on success, false on failure
(define-sdl SDL-PutAudioStreamData
  (_fun _SDL_AudioStream-pointer _pointer _int -> _sdl-bool)
  #:c-id SDL_PutAudioStreamData)

;; SDL_GetAudioStreamData: Get converted audio data from the stream
;; stream: the audio stream
;; buf: buffer to receive the converted audio data
;; len: maximum number of bytes to read
;; Returns: number of bytes read, or -1 on failure
(define-sdl SDL-GetAudioStreamData
  (_fun _SDL_AudioStream-pointer _pointer _int -> _int)
  #:c-id SDL_GetAudioStreamData)

;; SDL_GetAudioStreamAvailable: Get the number of bytes available in the stream
;; stream: the audio stream to query
;; Returns: number of converted bytes available, or -1 on failure
(define-sdl SDL-GetAudioStreamAvailable
  (_fun _SDL_AudioStream-pointer -> _int)
  #:c-id SDL_GetAudioStreamAvailable)

;; SDL_FlushAudioStream: Flush remaining data from the stream
;; Forces any pending data through the conversion process.
;; stream: the audio stream to flush
;; Returns: true on success, false on failure
(define-sdl SDL-FlushAudioStream
  (_fun _SDL_AudioStream-pointer -> _sdl-bool)
  #:c-id SDL_FlushAudioStream)

;; SDL_ClearAudioStream: Clear all data from the stream without processing
;; stream: the audio stream to clear
;; Returns: true on success, false on failure
(define-sdl SDL-ClearAudioStream
  (_fun _SDL_AudioStream-pointer -> _sdl-bool)
  #:c-id SDL_ClearAudioStream)

;; SDL_BindAudioStream: Bind an audio stream to a device for playback
;; devid: the audio device to bind to
;; stream: the audio stream to bind
;; Returns: true on success, false on failure
(define-sdl SDL-BindAudioStream
  (_fun _SDL_AudioDeviceID _SDL_AudioStream-pointer -> _sdl-bool)
  #:c-id SDL_BindAudioStream)

;; SDL_UnbindAudioStream: Unbind an audio stream from its device
;; stream: the audio stream to unbind
(define-sdl SDL-UnbindAudioStream
  (_fun _SDL_AudioStream-pointer -> _void)
  #:c-id SDL_UnbindAudioStream)

;; ============================================================================
;; Audio - WAV Loading
;; ============================================================================

;; SDL_LoadWAV: Load a WAV file from disk
;; path: the file path to load
;; spec: pointer to SDL_AudioSpec to receive the audio format
;; audio_buf: pointer to receive the audio data buffer (free with SDL_free)
;; audio_len: pointer to receive the length in bytes
;; Returns: true on success, false on failure
(define-sdl SDL-LoadWAV
  (_fun _string/utf-8
        _SDL_AudioSpec-pointer
        (audio_buf : (_ptr o _pointer))
        (audio_len : (_ptr o _uint32))
        -> (result : _sdl-bool)
        -> (values result audio_buf audio_len))
  #:c-id SDL_LoadWAV)
