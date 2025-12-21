#lang racket/base

;; SDL3 GPU Safe Wrappers
;;
;; High-level idiomatic Racket interface for the SDL3 GPU API.
;; Provides automatic resource cleanup via custodians.

(require ffi/unsafe
         ffi/unsafe/custodian
         "../raw/gpu.rkt"
         "../private/types.rkt"
         "../private/constants.rkt"
         "../private/safe-syntax.rkt")

(provide
 ;; Device
 gpu-device?
 make-gpu-device
 gpu-device-destroy!
 gpu-device-driver
 gpu-device-shader-formats
 gpu-supports-shader-formats?

 ;; Swapchain
 gpu-claim-window!
 gpu-release-window!
 gpu-swapchain-texture-format
 gpu-set-swapchain-parameters!
 gpu-acquire-swapchain-texture
 gpu-wait-for-swapchain!

 ;; Command buffers
 gpu-acquire-command-buffer
 gpu-submit!
 gpu-submit-and-acquire-fence!
 gpu-cancel-command-buffer!

 ;; Render pass
 gpu-begin-render-pass
 gpu-end-render-pass!

 ;; Graphics pipeline
 gpu-graphics-pipeline?
 make-gpu-graphics-pipeline
 gpu-graphics-pipeline-destroy!
 gpu-bind-graphics-pipeline!

 ;; Shaders
 gpu-shader?
 gpu-shader-ptr
 make-gpu-shader
 gpu-shader-destroy!

 ;; Buffers
 gpu-buffer?
 gpu-buffer-ptr
 make-gpu-buffer
 gpu-buffer-destroy!
 gpu-transfer-buffer?
 gpu-transfer-buffer-ptr
 make-gpu-transfer-buffer
 gpu-transfer-buffer-destroy!
 gpu-map-transfer-buffer
 gpu-unmap-transfer-buffer!

 ;; Copy pass
 gpu-begin-copy-pass
 gpu-end-copy-pass!
 gpu-upload-to-buffer!
 gpu-upload-to-texture!

 ;; Textures
 gpu-texture?
 make-gpu-texture
 gpu-texture-destroy!
 gpu-set-texture-name!

 ;; Samplers
 gpu-sampler?
 make-gpu-sampler
 gpu-sampler-destroy!

 ;; Drawing
 gpu-bind-vertex-buffers!
 gpu-bind-index-buffer!
 gpu-set-viewport!
 gpu-set-scissor!
 gpu-push-vertex-uniform-data!
 gpu-push-fragment-uniform-data!
 gpu-draw-primitives!
 gpu-draw-indexed-primitives!

 ;; Fences
 gpu-fence?
 gpu-query-fence
 gpu-release-fence!
 gpu-wait-for-idle!

 ;; Blit
 gpu-blit-texture!

 ;; Re-export constants and types
 (all-from-out "../private/constants.rkt")
 (all-from-out "../private/types.rkt"))

;; ============================================================================
;; Resource Wrappers
;; ============================================================================

;; GPU Device wrapper (simple case - just a pointer, destructor takes pointer)
(define-sdl-resource gpu-device SDL-DestroyGPUDevice)

;; Graphics Pipeline wrapper (needs device for cleanup)
(struct gpu-graphics-pipeline (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (p) (gpu-graphics-pipeline-ptr p)))

(define (make-gpu-graphics-pipeline device create-info)
  (define ptr (SDL-CreateGPUGraphicsPipeline (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-graphics-pipeline "Failed to create graphics pipeline"))
  (define pipeline (gpu-graphics-pipeline ptr device #f))
  (register-custodian-shutdown
   pipeline
   (lambda (p)
     (unless (gpu-graphics-pipeline-destroyed? p)
       (SDL-ReleaseGPUGraphicsPipeline (gpu-device-ptr (gpu-graphics-pipeline-device p))
                                       (gpu-graphics-pipeline-ptr p))
       (set-gpu-graphics-pipeline-destroyed?! p #t))))
  pipeline)

(define (gpu-graphics-pipeline-destroy! pipeline)
  (unless (gpu-graphics-pipeline-destroyed? pipeline)
    (SDL-ReleaseGPUGraphicsPipeline (gpu-device-ptr (gpu-graphics-pipeline-device pipeline))
                                    (gpu-graphics-pipeline-ptr pipeline))
    (set-gpu-graphics-pipeline-destroyed?! pipeline #t)))

;; Shader wrapper
(struct gpu-shader (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (s) (gpu-shader-ptr s)))

(define (make-gpu-shader device create-info)
  (define ptr (SDL-CreateGPUShader (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-shader "Failed to create shader"))
  (define shader (gpu-shader ptr device #f))
  (register-custodian-shutdown
   shader
   (lambda (s)
     (unless (gpu-shader-destroyed? s)
       (SDL-ReleaseGPUShader (gpu-device-ptr (gpu-shader-device s))
                             (gpu-shader-ptr s))
       (set-gpu-shader-destroyed?! s #t))))
  shader)

(define (gpu-shader-destroy! shader)
  (unless (gpu-shader-destroyed? shader)
    (SDL-ReleaseGPUShader (gpu-device-ptr (gpu-shader-device shader))
                          (gpu-shader-ptr shader))
    (set-gpu-shader-destroyed?! shader #t)))

;; Buffer wrapper
(struct gpu-buffer (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (b) (gpu-buffer-ptr b)))

(define (make-gpu-buffer device create-info)
  (define ptr (SDL-CreateGPUBuffer (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-buffer "Failed to create buffer"))
  (define buffer (gpu-buffer ptr device #f))
  (register-custodian-shutdown
   buffer
   (lambda (b)
     (unless (gpu-buffer-destroyed? b)
       (SDL-ReleaseGPUBuffer (gpu-device-ptr (gpu-buffer-device b))
                             (gpu-buffer-ptr b))
       (set-gpu-buffer-destroyed?! b #t))))
  buffer)

(define (gpu-buffer-destroy! buffer)
  (unless (gpu-buffer-destroyed? buffer)
    (SDL-ReleaseGPUBuffer (gpu-device-ptr (gpu-buffer-device buffer))
                          (gpu-buffer-ptr buffer))
    (set-gpu-buffer-destroyed?! buffer #t)))

;; Transfer Buffer wrapper
(struct gpu-transfer-buffer (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (b) (gpu-transfer-buffer-ptr b)))

(define (make-gpu-transfer-buffer device create-info)
  (define ptr (SDL-CreateGPUTransferBuffer (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-transfer-buffer "Failed to create transfer buffer"))
  (define buffer (gpu-transfer-buffer ptr device #f))
  (register-custodian-shutdown
   buffer
   (lambda (b)
     (unless (gpu-transfer-buffer-destroyed? b)
       (SDL-ReleaseGPUTransferBuffer (gpu-device-ptr (gpu-transfer-buffer-device b))
                                     (gpu-transfer-buffer-ptr b))
       (set-gpu-transfer-buffer-destroyed?! b #t))))
  buffer)

(define (gpu-transfer-buffer-destroy! buffer)
  (unless (gpu-transfer-buffer-destroyed? buffer)
    (SDL-ReleaseGPUTransferBuffer (gpu-device-ptr (gpu-transfer-buffer-device buffer))
                                  (gpu-transfer-buffer-ptr buffer))
    (set-gpu-transfer-buffer-destroyed?! buffer #t)))

;; Texture wrapper
(struct gpu-texture (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (t) (gpu-texture-ptr t)))

(define (make-gpu-texture device create-info)
  (define ptr (SDL-CreateGPUTexture (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-texture "Failed to create texture"))
  (define texture (gpu-texture ptr device #f))
  (register-custodian-shutdown
   texture
   (lambda (t)
     (unless (gpu-texture-destroyed? t)
       (SDL-ReleaseGPUTexture (gpu-device-ptr (gpu-texture-device t))
                              (gpu-texture-ptr t))
       (set-gpu-texture-destroyed?! t #t))))
  texture)

(define (gpu-texture-destroy! texture)
  (unless (gpu-texture-destroyed? texture)
    (SDL-ReleaseGPUTexture (gpu-device-ptr (gpu-texture-device texture))
                           (gpu-texture-ptr texture))
    (set-gpu-texture-destroyed?! texture #t)))

;; Sampler wrapper
(struct gpu-sampler (ptr device [destroyed? #:mutable])
  #:property prop:cpointer (lambda (s) (gpu-sampler-ptr s)))

(define (make-gpu-sampler device create-info)
  (define ptr (SDL-CreateGPUSampler (gpu-device-ptr device) create-info))
  (unless ptr
    (error 'make-gpu-sampler "Failed to create sampler"))
  (define sampler (gpu-sampler ptr device #f))
  (register-custodian-shutdown
   sampler
   (lambda (s)
     (unless (gpu-sampler-destroyed? s)
       (SDL-ReleaseGPUSampler (gpu-device-ptr (gpu-sampler-device s))
                              (gpu-sampler-ptr s))
       (set-gpu-sampler-destroyed?! s #t))))
  sampler)

(define (gpu-sampler-destroy! sampler)
  (unless (gpu-sampler-destroyed? sampler)
    (SDL-ReleaseGPUSampler (gpu-device-ptr (gpu-sampler-device sampler))
                           (gpu-sampler-ptr sampler))
    (set-gpu-sampler-destroyed?! sampler #t)))

;; Fence wrapper (no automatic cleanup - user must release)
(struct gpu-fence (ptr device)
  #:property prop:cpointer (lambda (f) (gpu-fence-ptr f)))

(define (gpu-release-fence! fence)
  (SDL-ReleaseGPUFence (gpu-device-ptr (gpu-fence-device fence))
                       (gpu-fence-ptr fence)))

;; ============================================================================
;; Device Functions
;; ============================================================================

(define (make-gpu-device #:shader-formats [formats SDL_GPU_SHADERFORMAT_SPIRV]
                         #:debug? [debug? #f]
                         #:driver [driver #f])
  (define ptr (SDL-CreateGPUDevice formats debug? driver))
  (unless ptr
    (error 'make-gpu-device "Failed to create GPU device"))
  (wrap-gpu-device ptr))

;; gpu-device-destroy! is generated by define-sdl-resource

(define (gpu-device-driver device)
  (SDL-GetGPUDeviceDriver (gpu-device-ptr device)))

(define (gpu-device-shader-formats device)
  (SDL-GetGPUShaderFormats (gpu-device-ptr device)))

(define (gpu-supports-shader-formats? formats #:driver [driver #f])
  (SDL-GPUSupportsShaderFormats formats driver))

;; ============================================================================
;; Swapchain Functions
;; ============================================================================

(define (gpu-claim-window! device window)
  (unless (SDL-ClaimWindowForGPUDevice (gpu-device-ptr device) window)
    (error 'gpu-claim-window! "Failed to claim window for GPU device")))

(define (gpu-release-window! device window)
  (SDL-ReleaseWindowFromGPUDevice (gpu-device-ptr device) window))

(define (gpu-swapchain-texture-format device window)
  (SDL-GetGPUSwapchainTextureFormat (gpu-device-ptr device) window))

(define (gpu-set-swapchain-parameters! device window composition present-mode)
  (unless (SDL-SetGPUSwapchainParameters (gpu-device-ptr device) window
                                          composition present-mode)
    (error 'gpu-set-swapchain-parameters! "Failed to set swapchain parameters")))

(define (gpu-acquire-swapchain-texture cmd-buffer window)
  (define-values (result texture width height)
    (SDL-AcquireGPUSwapchainTexture cmd-buffer window))
  (if result
      (values texture width height)
      (values #f 0 0)))

(define (gpu-wait-for-swapchain! device window)
  (unless (SDL-WaitForGPUSwapchain (gpu-device-ptr device) window)
    (error 'gpu-wait-for-swapchain! "Failed to wait for swapchain")))

;; ============================================================================
;; Command Buffer Functions
;; ============================================================================

(define (gpu-acquire-command-buffer device)
  (define cmd (SDL-AcquireGPUCommandBuffer (gpu-device-ptr device)))
  (unless cmd
    (error 'gpu-acquire-command-buffer "Failed to acquire command buffer"))
  cmd)

(define (gpu-submit! cmd-buffer)
  (unless (SDL-SubmitGPUCommandBuffer cmd-buffer)
    (error 'gpu-submit! "Failed to submit command buffer")))

(define (gpu-submit-and-acquire-fence! device cmd-buffer)
  (define fence-ptr (SDL-SubmitGPUCommandBufferAndAcquireFence cmd-buffer))
  (unless fence-ptr
    (error 'gpu-submit-and-acquire-fence! "Failed to submit and acquire fence"))
  (gpu-fence fence-ptr device))

(define (gpu-cancel-command-buffer! cmd-buffer)
  (SDL-CancelGPUCommandBuffer cmd-buffer))

;; ============================================================================
;; Render Pass Functions
;; ============================================================================

(define (gpu-begin-render-pass cmd-buffer color-targets
                                #:depth-stencil-target [depth-stencil #f])
  (define num-targets (if (list? color-targets) (length color-targets) 1))
  (define pass (SDL-BeginGPURenderPass cmd-buffer color-targets num-targets depth-stencil))
  (unless pass
    (error 'gpu-begin-render-pass "Failed to begin render pass"))
  pass)

(define (gpu-end-render-pass! pass)
  (SDL-EndGPURenderPass pass))

;; ============================================================================
;; Pipeline Functions
;; ============================================================================

(define (gpu-bind-graphics-pipeline! render-pass pipeline)
  (SDL-BindGPUGraphicsPipeline render-pass (gpu-graphics-pipeline-ptr pipeline)))

;; ============================================================================
;; Buffer Functions
;; ============================================================================

(define (gpu-map-transfer-buffer device buffer #:cycle? [cycle? #f])
  (SDL-MapGPUTransferBuffer (gpu-device-ptr device)
                            (gpu-transfer-buffer-ptr buffer)
                            cycle?))

(define (gpu-unmap-transfer-buffer! device buffer)
  (SDL-UnmapGPUTransferBuffer (gpu-device-ptr device)
                              (gpu-transfer-buffer-ptr buffer)))

;; ============================================================================
;; Copy Pass Functions
;; ============================================================================

(define (gpu-begin-copy-pass cmd-buffer)
  (define pass (SDL-BeginGPUCopyPass cmd-buffer))
  (unless pass
    (error 'gpu-begin-copy-pass "Failed to begin copy pass"))
  pass)

(define (gpu-end-copy-pass! pass)
  (SDL-EndGPUCopyPass pass))

(define (gpu-upload-to-buffer! copy-pass source destination #:cycle? [cycle? #f])
  (SDL-UploadToGPUBuffer copy-pass source destination cycle?))

(define (gpu-upload-to-texture! copy-pass source destination #:cycle? [cycle? #f])
  (SDL-UploadToGPUTexture copy-pass source destination cycle?))

;; ============================================================================
;; Texture Functions
;; ============================================================================

(define (gpu-set-texture-name! device texture name)
  (SDL-SetGPUTextureName (gpu-device-ptr device)
                         (gpu-texture-ptr texture)
                         name))

;; ============================================================================
;; Drawing Functions
;; ============================================================================

(define (gpu-bind-vertex-buffers! render-pass bindings #:first-slot [first-slot 0])
  (define num-bindings (if (list? bindings) (length bindings) 1))
  (SDL-BindGPUVertexBuffers render-pass first-slot bindings num-bindings))

(define (gpu-bind-index-buffer! render-pass binding element-size)
  (SDL-BindGPUIndexBuffer render-pass binding element-size))

(define (gpu-set-viewport! render-pass viewport)
  (SDL-SetGPUViewport render-pass viewport))

(define (gpu-set-scissor! render-pass rect)
  (SDL-SetGPUScissor render-pass rect))

(define (gpu-push-vertex-uniform-data! cmd-buffer slot data length)
  (SDL-PushGPUVertexUniformData cmd-buffer slot data length))

(define (gpu-push-fragment-uniform-data! cmd-buffer slot data length)
  (SDL-PushGPUFragmentUniformData cmd-buffer slot data length))

(define (gpu-draw-primitives! render-pass num-vertices
                              #:num-instances [num-instances 1]
                              #:first-vertex [first-vertex 0]
                              #:first-instance [first-instance 0])
  (SDL-DrawGPUPrimitives render-pass num-vertices num-instances
                         first-vertex first-instance))

(define (gpu-draw-indexed-primitives! render-pass num-indices
                                       #:num-instances [num-instances 1]
                                       #:first-index [first-index 0]
                                       #:vertex-offset [vertex-offset 0]
                                       #:first-instance [first-instance 0])
  (SDL-DrawGPUIndexedPrimitives render-pass num-indices num-instances
                                 first-index vertex-offset first-instance))

;; ============================================================================
;; Fence Functions
;; ============================================================================

(define (gpu-query-fence fence)
  (SDL-QueryGPUFence (gpu-device-ptr (gpu-fence-device fence))
                     (gpu-fence-ptr fence)))

(define (gpu-wait-for-idle! device)
  (unless (SDL-WaitForGPUIdle (gpu-device-ptr device))
    (error 'gpu-wait-for-idle! "Failed to wait for GPU idle")))

;; ============================================================================
;; Blit Functions
;; ============================================================================

(define (gpu-blit-texture! cmd-buffer blit-info)
  (SDL-BlitGPUTexture cmd-buffer blit-info))
