#lang racket/base

;; SDL3 Vulkan Functions
;;
;; Functions for Vulkan surface creation and management.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt")

(provide SDL-Vulkan-LoadLibrary
         SDL-Vulkan-GetVkGetInstanceProcAddr
         SDL-Vulkan-UnloadLibrary
         SDL-Vulkan-GetInstanceExtensions
         SDL-Vulkan-CreateSurface
         SDL-Vulkan-DestroySurface
         SDL-Vulkan-GetPresentationSupport)

;; ============================================================================
;; Vulkan Loading
;; ============================================================================

;; SDL_Vulkan_LoadLibrary: Dynamically load the Vulkan loader library
;; path: platform dependent Vulkan loader library name or NULL
;; Returns: true on success or false on failure
(define-sdl SDL-Vulkan-LoadLibrary (_fun _string/utf-8 -> _sdl-bool)
  #:c-id SDL_Vulkan_LoadLibrary)

;; SDL_Vulkan_GetVkGetInstanceProcAddr: Get the address of the vkGetInstanceProcAddr function
;; Returns: function pointer or NULL on failure
(define-sdl SDL-Vulkan-GetVkGetInstanceProcAddr (_fun -> _pointer)
  #:c-id SDL_Vulkan_GetVkGetInstanceProcAddr)

;; SDL_Vulkan_UnloadLibrary: Unload the Vulkan library
(define-sdl SDL-Vulkan-UnloadLibrary (_fun -> _void)
  #:c-id SDL_Vulkan_UnloadLibrary)

;; ============================================================================
;; Vulkan Configuration
;; ============================================================================

;; SDL_Vulkan_GetInstanceExtensions: Get the Vulkan instance extensions needed
;; count: pointer to receive the number of extensions
;; Returns: array of extension name strings, or NULL on failure
(define-sdl SDL-Vulkan-GetInstanceExtensions
  (_fun (count : (_ptr o _uint32))
        -> (result : _pointer)
        -> (if result
               (for/list ([i (in-range count)])
                 (ptr-ref result _string/utf-8 i))
               #f))
  #:c-id SDL_Vulkan_GetInstanceExtensions)

;; ============================================================================
;; Vulkan Surface
;; ============================================================================

;; SDL_Vulkan_CreateSurface: Create a Vulkan rendering surface for a window
;; window: the window to attach the surface to
;; instance: the Vulkan instance handle
;; allocator: VkAllocationCallbacks pointer, or NULL
;; surface: pointer to VkSurfaceKHR handle
;; Returns: true on success or false on failure
(define-sdl SDL-Vulkan-CreateSurface
  (_fun _SDL_Window-pointer _VkInstance _VkAllocationCallbacks-pointer/null 
        (surface : (_ptr o _VkSurfaceKHR))
        -> (result : _sdl-bool)
        -> (values result surface))
  #:c-id SDL_Vulkan_CreateSurface)

;; SDL_Vulkan_DestroySurface: Destroy the Vulkan rendering surface of a window
;; instance: the Vulkan instance handle
;; surface: VkSurfaceKHR handle to destroy
;; allocator: VkAllocationCallbacks pointer, or NULL
(define-sdl SDL-Vulkan-DestroySurface
  (_fun _VkInstance _VkSurfaceKHR _VkAllocationCallbacks-pointer/null -> _void)
  #:c-id SDL_Vulkan_DestroySurface)

;; SDL_Vulkan_GetPresentationSupport: Query support for presentation
;; instance: the Vulkan instance handle
;; physicalDevice: Vulkan physical device handle
;; queueFamilyIndex: queue family index
;; Returns: true if supported, false otherwise
(define-sdl SDL-Vulkan-GetPresentationSupport
  (_fun _VkInstance _VkPhysicalDevice _uint32 -> _sdl-bool)
  #:c-id SDL_Vulkan_GetPresentationSupport)
