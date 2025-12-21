#lang racket/base

;; GPU Info Example
;;
;; Shows how to create a GPU device and query information about it.
;; This is a simple example that doesn't render anything.

(require sdl3
         sdl3/raw)

;; Check what shader formats are supported
(printf "=== SDL3 GPU API Info ===\n\n")

(printf "Shader Format Support:\n")
(printf "  Metal library: ~a\n" (gpu-supports-shader-formats? SDL_GPU_SHADERFORMAT_METALLIB))
(printf "  MSL source: ~a\n" (gpu-supports-shader-formats? SDL_GPU_SHADERFORMAT_MSL))
(printf "  SPIR-V: ~a\n" (gpu-supports-shader-formats? SDL_GPU_SHADERFORMAT_SPIRV))
(printf "  DXBC: ~a\n" (gpu-supports-shader-formats? SDL_GPU_SHADERFORMAT_DXBC))
(printf "  DXIL: ~a\n" (gpu-supports-shader-formats? SDL_GPU_SHADERFORMAT_DXIL))
(printf "\n")

;; Initialize SDL
(sdl-init!)

;; Create a GPU device with Metal shader support on macOS
(define device (make-gpu-device #:shader-formats SDL_GPU_SHADERFORMAT_MSL
                                 #:debug? #t))

(printf "GPU Device Created!\n")
(printf "  Driver: ~a\n" (gpu-device-driver device))
(printf "  Supported formats: ~a\n" (gpu-device-shader-formats device))

;; Create a window to test swapchain
(define win (make-window "GPU Test" 640 480))

;; Claim the window for GPU rendering
(gpu-claim-window! device win)
(printf "  Window claimed for GPU rendering\n")

;; Get swapchain texture format
(define format (gpu-swapchain-texture-format device win))
(printf "  Swapchain texture format: ~a\n" format)

;; Release window
(gpu-release-window! device win)
(printf "  Window released\n")

;; Cleanup
(window-destroy! win)
(gpu-device-destroy! device)
(printf "\nGPU device destroyed. Done!\n")
