#lang racket/base

;; SDL3 GPU Functions
;;
;; The SDL GPU API provides a cross-platform abstraction for modern graphics
;; hardware. It supports multiple backends: Vulkan, Direct3D 11/12, and Metal.

(require ffi/unsafe
         "../private/lib.rkt"
         "../private/types.rkt"
         "../private/constants.rkt")

(provide
 ;; Device management
 SDL-GPUSupportsShaderFormats
 SDL-GPUSupportsProperties
 SDL-CreateGPUDevice
 SDL-CreateGPUDeviceWithProperties
 SDL-DestroyGPUDevice
 SDL-GetGPUDeviceDriver
 SDL-GetGPUShaderFormats

 ;; Swapchain
 SDL-ClaimWindowForGPUDevice
 SDL-ReleaseWindowFromGPUDevice
 SDL-SetGPUSwapchainParameters
 SDL-GetGPUSwapchainTextureFormat
 SDL-AcquireGPUSwapchainTexture
 SDL-WaitForGPUSwapchain

 ;; Command buffers
 SDL-AcquireGPUCommandBuffer
 SDL-SubmitGPUCommandBuffer
 SDL-SubmitGPUCommandBufferAndAcquireFence
 SDL-CancelGPUCommandBuffer

 ;; Render pass
 SDL-BeginGPURenderPass
 SDL-EndGPURenderPass

 ;; Graphics pipeline
 SDL-CreateGPUGraphicsPipeline
 SDL-ReleaseGPUGraphicsPipeline
 SDL-BindGPUGraphicsPipeline

 ;; Shaders
 SDL-CreateGPUShader
 SDL-ReleaseGPUShader

 ;; Buffers
 SDL-CreateGPUBuffer
 SDL-ReleaseGPUBuffer
 SDL-CreateGPUTransferBuffer
 SDL-ReleaseGPUTransferBuffer
 SDL-MapGPUTransferBuffer
 SDL-UnmapGPUTransferBuffer

 ;; Copy pass
 SDL-BeginGPUCopyPass
 SDL-EndGPUCopyPass
 SDL-UploadToGPUBuffer
 SDL-UploadToGPUTexture
 SDL-DownloadFromGPUBuffer
 SDL-DownloadFromGPUTexture
 SDL-CopyGPUBufferToBuffer
 SDL-CopyGPUTextureToTexture

 ;; Textures
 SDL-CreateGPUTexture
 SDL-ReleaseGPUTexture
 SDL-SetGPUTextureName

 ;; Samplers
 SDL-CreateGPUSampler
 SDL-ReleaseGPUSampler

 ;; Drawing
 SDL-BindGPUVertexBuffers
 SDL-BindGPUIndexBuffer
 SDL-SetGPUViewport
 SDL-SetGPUScissor
 SDL-SetGPUBlendConstants
 SDL-SetGPUStencilReference
 SDL-PushGPUVertexUniformData
 SDL-PushGPUFragmentUniformData
 SDL-DrawGPUPrimitives
 SDL-DrawGPUPrimitivesIndirect
 SDL-DrawGPUIndexedPrimitives
 SDL-DrawGPUIndexedPrimitivesIndirect

 ;; Compute pipeline
 SDL-CreateGPUComputePipeline
 SDL-ReleaseGPUComputePipeline
 SDL-BeginGPUComputePass
 SDL-EndGPUComputePass
 SDL-BindGPUComputePipeline
 SDL-BindGPUComputeStorageBuffers
 SDL-BindGPUComputeStorageTextures
 SDL-DispatchGPUCompute
 SDL-DispatchGPUComputeIndirect

 ;; Binding resources
 SDL-BindGPUVertexStorageBuffers
 SDL-BindGPUVertexStorageTextures
 SDL-BindGPUVertexSamplers
 SDL-BindGPUFragmentStorageBuffers
 SDL-BindGPUFragmentStorageTextures
 SDL-BindGPUFragmentSamplers
 SDL-PushGPUVertexUniformData
 SDL-PushGPUFragmentUniformData
 SDL-PushGPUComputeUniformData

 ;; Fences
 SDL-QueryGPUFence
 SDL-ReleaseGPUFence
 SDL-WaitForGPUFences
 SDL-WaitForGPUIdle

 ;; Blit
 SDL-BlitGPUTexture)

;; ============================================================================
;; Device Management
;; ============================================================================

;; SDL_GPUSupportsShaderFormats: Check shader format support
(define-sdl SDL-GPUSupportsShaderFormats
  (_fun _SDL_GPUShaderFormat _string/utf-8 -> _sdl-bool)
  #:c-id SDL_GPUSupportsShaderFormats)

;; SDL_GPUSupportsProperties: Check property-based device support
(define-sdl SDL-GPUSupportsProperties
  (_fun _uint32 -> _sdl-bool)
  #:c-id SDL_GPUSupportsProperties)

;; SDL_CreateGPUDevice: Create a GPU device
;; format_flags: Shader format flags
;; debug_mode: Enable validation layers
;; name: Preferred driver name (NULL for auto)
(define-sdl SDL-CreateGPUDevice
  (_fun _SDL_GPUShaderFormat _sdl-bool _string/utf-8 -> _SDL_GPUDevice-pointer/null)
  #:c-id SDL_CreateGPUDevice)

;; SDL_CreateGPUDeviceWithProperties: Create device with properties
(define-sdl SDL-CreateGPUDeviceWithProperties
  (_fun _uint32 -> _SDL_GPUDevice-pointer/null)
  #:c-id SDL_CreateGPUDeviceWithProperties)

;; SDL_DestroyGPUDevice: Destroy a GPU device
(define-sdl SDL-DestroyGPUDevice
  (_fun _SDL_GPUDevice-pointer -> _void)
  #:c-id SDL_DestroyGPUDevice)

;; SDL_GetGPUDeviceDriver: Get backend driver name
(define-sdl SDL-GetGPUDeviceDriver
  (_fun _SDL_GPUDevice-pointer -> _string/utf-8)
  #:c-id SDL_GetGPUDeviceDriver)

;; SDL_GetGPUShaderFormats: Get supported shader formats
(define-sdl SDL-GetGPUShaderFormats
  (_fun _SDL_GPUDevice-pointer -> _SDL_GPUShaderFormat)
  #:c-id SDL_GetGPUShaderFormats)

;; ============================================================================
;; Swapchain
;; ============================================================================

;; SDL_ClaimWindowForGPUDevice: Associate window with GPU device
(define-sdl SDL-ClaimWindowForGPUDevice
  (_fun _SDL_GPUDevice-pointer _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_ClaimWindowForGPUDevice)

;; SDL_ReleaseWindowFromGPUDevice: Disassociate window from GPU device
(define-sdl SDL-ReleaseWindowFromGPUDevice
  (_fun _SDL_GPUDevice-pointer _SDL_Window-pointer -> _void)
  #:c-id SDL_ReleaseWindowFromGPUDevice)

;; SDL_SetGPUSwapchainParameters: Configure swapchain
(define-sdl SDL-SetGPUSwapchainParameters
  (_fun _SDL_GPUDevice-pointer _SDL_Window-pointer
        _SDL_GPUSwapchainComposition _SDL_GPUPresentMode
        -> _sdl-bool)
  #:c-id SDL_SetGPUSwapchainParameters)

;; SDL_GetGPUSwapchainTextureFormat: Get swapchain texture format
(define-sdl SDL-GetGPUSwapchainTextureFormat
  (_fun _SDL_GPUDevice-pointer _SDL_Window-pointer -> _SDL_GPUTextureFormat)
  #:c-id SDL_GetGPUSwapchainTextureFormat)

;; SDL_AcquireGPUSwapchainTexture: Get next swapchain texture
;; Returns texture and dimensions via output parameters
(define-sdl SDL-AcquireGPUSwapchainTexture
  (_fun _SDL_GPUCommandBuffer-pointer
        _SDL_Window-pointer
        (texture : (_ptr o _SDL_GPUTexture-pointer/null))
        (width : (_ptr o _uint32))
        (height : (_ptr o _uint32))
        -> (result : _sdl-bool)
        -> (values result texture width height))
  #:c-id SDL_AcquireGPUSwapchainTexture)

;; SDL_WaitForGPUSwapchain: Wait for swapchain to be available
(define-sdl SDL-WaitForGPUSwapchain
  (_fun _SDL_GPUDevice-pointer _SDL_Window-pointer -> _sdl-bool)
  #:c-id SDL_WaitForGPUSwapchain)

;; ============================================================================
;; Command Buffers
;; ============================================================================

;; SDL_AcquireGPUCommandBuffer: Get a command buffer to record into
(define-sdl SDL-AcquireGPUCommandBuffer
  (_fun _SDL_GPUDevice-pointer -> _SDL_GPUCommandBuffer-pointer/null)
  #:c-id SDL_AcquireGPUCommandBuffer)

;; SDL_SubmitGPUCommandBuffer: Submit command buffer for execution
(define-sdl SDL-SubmitGPUCommandBuffer
  (_fun _SDL_GPUCommandBuffer-pointer -> _sdl-bool)
  #:c-id SDL_SubmitGPUCommandBuffer)

;; SDL_SubmitGPUCommandBufferAndAcquireFence: Submit and get fence
(define-sdl SDL-SubmitGPUCommandBufferAndAcquireFence
  (_fun _SDL_GPUCommandBuffer-pointer -> _SDL_GPUFence-pointer/null)
  #:c-id SDL_SubmitGPUCommandBufferAndAcquireFence)

;; SDL_CancelGPUCommandBuffer: Cancel a command buffer
(define-sdl SDL-CancelGPUCommandBuffer
  (_fun _SDL_GPUCommandBuffer-pointer -> _sdl-bool)
  #:c-id SDL_CancelGPUCommandBuffer)

;; ============================================================================
;; Render Pass
;; ============================================================================

;; SDL_BeginGPURenderPass: Begin a render pass
;; color_targets: Array of color target infos
;; num_color_targets: Number of color targets
;; depth_stencil_target: Optional depth/stencil target (or NULL)
;; Use _pointer for color_targets to accept malloc'd arrays
(define-sdl SDL-BeginGPURenderPass
  (_fun _SDL_GPUCommandBuffer-pointer
        _pointer  ; color targets array
        _uint32
        _pointer  ; depth stencil target (nullable)
        -> _SDL_GPURenderPass-pointer/null)
  #:c-id SDL_BeginGPURenderPass)

;; SDL_EndGPURenderPass: End current render pass
(define-sdl SDL-EndGPURenderPass
  (_fun _SDL_GPURenderPass-pointer -> _void)
  #:c-id SDL_EndGPURenderPass)

;; ============================================================================
;; Graphics Pipeline
;; ============================================================================

;; SDL_CreateGPUGraphicsPipeline: Create a graphics pipeline
(define-sdl SDL-CreateGPUGraphicsPipeline
  (_fun _SDL_GPUDevice-pointer _SDL_GPUGraphicsPipelineCreateInfo-pointer
        -> _SDL_GPUGraphicsPipeline-pointer/null)
  #:c-id SDL_CreateGPUGraphicsPipeline)

;; SDL_ReleaseGPUGraphicsPipeline: Release a graphics pipeline
(define-sdl SDL-ReleaseGPUGraphicsPipeline
  (_fun _SDL_GPUDevice-pointer _SDL_GPUGraphicsPipeline-pointer -> _void)
  #:c-id SDL_ReleaseGPUGraphicsPipeline)

;; SDL_BindGPUGraphicsPipeline: Bind pipeline for drawing
(define-sdl SDL-BindGPUGraphicsPipeline
  (_fun _SDL_GPURenderPass-pointer _SDL_GPUGraphicsPipeline-pointer -> _void)
  #:c-id SDL_BindGPUGraphicsPipeline)

;; ============================================================================
;; Shaders
;; ============================================================================

;; SDL_CreateGPUShader: Create a shader from bytecode
(define-sdl SDL-CreateGPUShader
  (_fun _SDL_GPUDevice-pointer _SDL_GPUShaderCreateInfo-pointer
        -> _SDL_GPUShader-pointer/null)
  #:c-id SDL_CreateGPUShader)

;; SDL_ReleaseGPUShader: Release a shader
(define-sdl SDL-ReleaseGPUShader
  (_fun _SDL_GPUDevice-pointer _SDL_GPUShader-pointer -> _void)
  #:c-id SDL_ReleaseGPUShader)

;; ============================================================================
;; Buffers
;; ============================================================================

;; SDL_CreateGPUBuffer: Create a GPU buffer
(define-sdl SDL-CreateGPUBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUBufferCreateInfo-pointer
        -> _SDL_GPUBuffer-pointer/null)
  #:c-id SDL_CreateGPUBuffer)

;; SDL_ReleaseGPUBuffer: Release a GPU buffer
(define-sdl SDL-ReleaseGPUBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUBuffer-pointer -> _void)
  #:c-id SDL_ReleaseGPUBuffer)

;; SDL_CreateGPUTransferBuffer: Create a transfer buffer
(define-sdl SDL-CreateGPUTransferBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTransferBufferCreateInfo-pointer
        -> _SDL_GPUTransferBuffer-pointer/null)
  #:c-id SDL_CreateGPUTransferBuffer)

;; SDL_ReleaseGPUTransferBuffer: Release a transfer buffer
(define-sdl SDL-ReleaseGPUTransferBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTransferBuffer-pointer -> _void)
  #:c-id SDL_ReleaseGPUTransferBuffer)

;; SDL_MapGPUTransferBuffer: Map transfer buffer for CPU access
;; cycle: If true, cycle the buffer to avoid sync
(define-sdl SDL-MapGPUTransferBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTransferBuffer-pointer _sdl-bool
        -> _pointer)
  #:c-id SDL_MapGPUTransferBuffer)

;; SDL_UnmapGPUTransferBuffer: Unmap transfer buffer
(define-sdl SDL-UnmapGPUTransferBuffer
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTransferBuffer-pointer -> _void)
  #:c-id SDL_UnmapGPUTransferBuffer)

;; ============================================================================
;; Copy Pass
;; ============================================================================

;; SDL_BeginGPUCopyPass: Begin a copy pass
(define-sdl SDL-BeginGPUCopyPass
  (_fun _SDL_GPUCommandBuffer-pointer -> _SDL_GPUCopyPass-pointer/null)
  #:c-id SDL_BeginGPUCopyPass)

;; SDL_EndGPUCopyPass: End a copy pass
(define-sdl SDL-EndGPUCopyPass
  (_fun _SDL_GPUCopyPass-pointer -> _void)
  #:c-id SDL_EndGPUCopyPass)

;; SDL_UploadToGPUBuffer: Copy from transfer buffer to GPU buffer
(define-sdl SDL-UploadToGPUBuffer
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUTransferBufferLocation-pointer
        _SDL_GPUBufferRegion-pointer
        _sdl-bool
        -> _void)
  #:c-id SDL_UploadToGPUBuffer)

;; SDL_UploadToGPUTexture: Copy from transfer buffer to texture
(define-sdl SDL-UploadToGPUTexture
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUTextureTransferInfo-pointer
        _SDL_GPUTextureRegion-pointer
        _sdl-bool
        -> _void)
  #:c-id SDL_UploadToGPUTexture)

;; SDL_DownloadFromGPUBuffer: Copy from GPU buffer to transfer buffer
(define-sdl SDL-DownloadFromGPUBuffer
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUBufferRegion-pointer
        _SDL_GPUTransferBufferLocation-pointer
        -> _void)
  #:c-id SDL_DownloadFromGPUBuffer)

;; SDL_DownloadFromGPUTexture: Copy from texture to transfer buffer
(define-sdl SDL-DownloadFromGPUTexture
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUTextureRegion-pointer
        _SDL_GPUTextureTransferInfo-pointer
        -> _void)
  #:c-id SDL_DownloadFromGPUTexture)

;; SDL_CopyGPUBufferToBuffer: Copy between GPU buffers
(define-sdl SDL-CopyGPUBufferToBuffer
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUBufferLocation-pointer
        _SDL_GPUBufferLocation-pointer
        _uint32
        _sdl-bool
        -> _void)
  #:c-id SDL_CopyGPUBufferToBuffer)

;; SDL_CopyGPUTextureToTexture: Copy between textures
(define-sdl SDL-CopyGPUTextureToTexture
  (_fun _SDL_GPUCopyPass-pointer
        _SDL_GPUTextureLocation-pointer
        _SDL_GPUTextureLocation-pointer
        _uint32 _uint32 _uint32
        _sdl-bool
        -> _void)
  #:c-id SDL_CopyGPUTextureToTexture)

;; ============================================================================
;; Textures
;; ============================================================================

;; SDL_CreateGPUTexture: Create a texture
(define-sdl SDL-CreateGPUTexture
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTextureCreateInfo-pointer
        -> _SDL_GPUTexture-pointer/null)
  #:c-id SDL_CreateGPUTexture)

;; SDL_ReleaseGPUTexture: Release a texture
(define-sdl SDL-ReleaseGPUTexture
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTexture-pointer -> _void)
  #:c-id SDL_ReleaseGPUTexture)

;; SDL_SetGPUTextureName: Set debug name for texture
(define-sdl SDL-SetGPUTextureName
  (_fun _SDL_GPUDevice-pointer _SDL_GPUTexture-pointer _string/utf-8 -> _void)
  #:c-id SDL_SetGPUTextureName)

;; ============================================================================
;; Samplers
;; ============================================================================

;; SDL_CreateGPUSampler: Create a sampler
(define-sdl SDL-CreateGPUSampler
  (_fun _SDL_GPUDevice-pointer _SDL_GPUSamplerCreateInfo-pointer
        -> _SDL_GPUSampler-pointer/null)
  #:c-id SDL_CreateGPUSampler)

;; SDL_ReleaseGPUSampler: Release a sampler
(define-sdl SDL-ReleaseGPUSampler
  (_fun _SDL_GPUDevice-pointer _SDL_GPUSampler-pointer -> _void)
  #:c-id SDL_ReleaseGPUSampler)

;; ============================================================================
;; Drawing
;; ============================================================================

;; SDL_BindGPUVertexBuffers: Bind vertex buffers
;; Use _pointer for bindings array to accept malloc'd arrays
(define-sdl SDL-BindGPUVertexBuffers
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _pointer ; array of bindings
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUVertexBuffers)

;; SDL_BindGPUIndexBuffer: Bind index buffer
;; Use _pointer for binding to accept malloc'd structs
(define-sdl SDL-BindGPUIndexBuffer
  (_fun _SDL_GPURenderPass-pointer
        _pointer
        _SDL_GPUIndexElementSize
        -> _void)
  #:c-id SDL_BindGPUIndexBuffer)

;; SDL_SetGPUViewport: Set viewport
(define-sdl SDL-SetGPUViewport
  (_fun _SDL_GPURenderPass-pointer _SDL_GPUViewport-pointer -> _void)
  #:c-id SDL_SetGPUViewport)

;; SDL_SetGPUScissor: Set scissor rect
(define-sdl SDL-SetGPUScissor
  (_fun _SDL_GPURenderPass-pointer _SDL_Rect-pointer -> _void)
  #:c-id SDL_SetGPUScissor)

;; SDL_SetGPUBlendConstants: Set blend constant color
(define-sdl SDL-SetGPUBlendConstants
  (_fun _SDL_GPURenderPass-pointer _SDL_FColor-pointer -> _void)
  #:c-id SDL_SetGPUBlendConstants)

;; SDL_SetGPUStencilReference: Set stencil reference value
(define-sdl SDL-SetGPUStencilReference
  (_fun _SDL_GPURenderPass-pointer _uint8 -> _void)
  #:c-id SDL_SetGPUStencilReference)

;; SDL_DrawGPUPrimitives: Draw non-indexed primitives
(define-sdl SDL-DrawGPUPrimitives
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; num_vertices
        _uint32  ; num_instances
        _uint32  ; first_vertex
        _uint32  ; first_instance
        -> _void)
  #:c-id SDL_DrawGPUPrimitives)

;; SDL_DrawGPUPrimitivesIndirect: Draw non-indexed with indirect buffer
(define-sdl SDL-DrawGPUPrimitivesIndirect
  (_fun _SDL_GPURenderPass-pointer
        _SDL_GPUBuffer-pointer
        _uint32  ; offset
        _uint32  ; draw_count
        -> _void)
  #:c-id SDL_DrawGPUPrimitivesIndirect)

;; SDL_DrawGPUIndexedPrimitives: Draw indexed primitives
(define-sdl SDL-DrawGPUIndexedPrimitives
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; num_indices
        _uint32  ; num_instances
        _uint32  ; first_index
        _sint32  ; vertex_offset
        _uint32  ; first_instance
        -> _void)
  #:c-id SDL_DrawGPUIndexedPrimitives)

;; SDL_DrawGPUIndexedPrimitivesIndirect: Draw indexed with indirect buffer
(define-sdl SDL-DrawGPUIndexedPrimitivesIndirect
  (_fun _SDL_GPURenderPass-pointer
        _SDL_GPUBuffer-pointer
        _uint32  ; offset
        _uint32  ; draw_count
        -> _void)
  #:c-id SDL_DrawGPUIndexedPrimitivesIndirect)

;; ============================================================================
;; Compute Pipeline
;; ============================================================================

;; SDL_CreateGPUComputePipeline: Create compute pipeline
(define-sdl SDL-CreateGPUComputePipeline
  (_fun _SDL_GPUDevice-pointer _SDL_GPUComputePipelineCreateInfo-pointer
        -> _SDL_GPUComputePipeline-pointer/null)
  #:c-id SDL_CreateGPUComputePipeline)

;; SDL_ReleaseGPUComputePipeline: Release compute pipeline
(define-sdl SDL-ReleaseGPUComputePipeline
  (_fun _SDL_GPUDevice-pointer _SDL_GPUComputePipeline-pointer -> _void)
  #:c-id SDL_ReleaseGPUComputePipeline)

;; SDL_BeginGPUComputePass: Begin compute pass
;; storage_texture_bindings and storage_buffer_bindings can be NULL
(define-sdl SDL-BeginGPUComputePass
  (_fun _SDL_GPUCommandBuffer-pointer
        _pointer  ; SDL_GPUStorageTextureReadWriteBinding* or NULL
        _uint32
        _pointer  ; SDL_GPUStorageBufferReadWriteBinding* or NULL
        _uint32
        -> _SDL_GPUComputePass-pointer/null)
  #:c-id SDL_BeginGPUComputePass)

;; SDL_EndGPUComputePass: End compute pass
(define-sdl SDL-EndGPUComputePass
  (_fun _SDL_GPUComputePass-pointer -> _void)
  #:c-id SDL_EndGPUComputePass)

;; SDL_BindGPUComputePipeline: Bind compute pipeline
(define-sdl SDL-BindGPUComputePipeline
  (_fun _SDL_GPUComputePass-pointer _SDL_GPUComputePipeline-pointer -> _void)
  #:c-id SDL_BindGPUComputePipeline)

;; SDL_BindGPUComputeStorageBuffers: Bind storage buffers for compute
(define-sdl SDL-BindGPUComputeStorageBuffers
  (_fun _SDL_GPUComputePass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUBuffer* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUComputeStorageBuffers)

;; SDL_BindGPUComputeStorageTextures: Bind storage textures for compute
(define-sdl SDL-BindGPUComputeStorageTextures
  (_fun _SDL_GPUComputePass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUTexture* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUComputeStorageTextures)

;; SDL_DispatchGPUCompute: Dispatch compute work
(define-sdl SDL-DispatchGPUCompute
  (_fun _SDL_GPUComputePass-pointer
        _uint32  ; groupcount_x
        _uint32  ; groupcount_y
        _uint32  ; groupcount_z
        -> _void)
  #:c-id SDL_DispatchGPUCompute)

;; SDL_DispatchGPUComputeIndirect: Dispatch compute with indirect buffer
(define-sdl SDL-DispatchGPUComputeIndirect
  (_fun _SDL_GPUComputePass-pointer
        _SDL_GPUBuffer-pointer
        _uint32  ; offset
        -> _void)
  #:c-id SDL_DispatchGPUComputeIndirect)

;; ============================================================================
;; Binding Resources
;; ============================================================================

;; SDL_BindGPUVertexStorageBuffers: Bind storage buffers for vertex stage
(define-sdl SDL-BindGPUVertexStorageBuffers
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUBuffer* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUVertexStorageBuffers)

;; SDL_BindGPUVertexStorageTextures: Bind storage textures for vertex stage
(define-sdl SDL-BindGPUVertexStorageTextures
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUTexture* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUVertexStorageTextures)

;; SDL_BindGPUVertexSamplers: Bind texture samplers for vertex stage
(define-sdl SDL-BindGPUVertexSamplers
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _SDL_GPUTextureSamplerBinding-pointer
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUVertexSamplers)

;; SDL_BindGPUFragmentStorageBuffers: Bind storage buffers for fragment stage
(define-sdl SDL-BindGPUFragmentStorageBuffers
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUBuffer* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUFragmentStorageBuffers)

;; SDL_BindGPUFragmentStorageTextures: Bind storage textures for fragment stage
(define-sdl SDL-BindGPUFragmentStorageTextures
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _pointer ; SDL_GPUTexture* const*
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUFragmentStorageTextures)

;; SDL_BindGPUFragmentSamplers: Bind texture samplers for fragment stage
(define-sdl SDL-BindGPUFragmentSamplers
  (_fun _SDL_GPURenderPass-pointer
        _uint32  ; first_slot
        _SDL_GPUTextureSamplerBinding-pointer
        _uint32  ; num_bindings
        -> _void)
  #:c-id SDL_BindGPUFragmentSamplers)

;; SDL_PushGPUVertexUniformData: Push uniform data for vertex stage
(define-sdl SDL-PushGPUVertexUniformData
  (_fun _SDL_GPUCommandBuffer-pointer
        _uint32  ; slot_index
        _pointer ; data
        _uint32  ; length
        -> _void)
  #:c-id SDL_PushGPUVertexUniformData)

;; SDL_PushGPUFragmentUniformData: Push uniform data for fragment stage
(define-sdl SDL-PushGPUFragmentUniformData
  (_fun _SDL_GPUCommandBuffer-pointer
        _uint32  ; slot_index
        _pointer ; data
        _uint32  ; length
        -> _void)
  #:c-id SDL_PushGPUFragmentUniformData)

;; SDL_PushGPUComputeUniformData: Push uniform data for compute stage
(define-sdl SDL-PushGPUComputeUniformData
  (_fun _SDL_GPUCommandBuffer-pointer
        _uint32  ; slot_index
        _pointer ; data
        _uint32  ; length
        -> _void)
  #:c-id SDL_PushGPUComputeUniformData)

;; ============================================================================
;; Fences
;; ============================================================================

;; SDL_QueryGPUFence: Check if fence is signaled
(define-sdl SDL-QueryGPUFence
  (_fun _SDL_GPUDevice-pointer _SDL_GPUFence-pointer -> _sdl-bool)
  #:c-id SDL_QueryGPUFence)

;; SDL_ReleaseGPUFence: Release a fence
(define-sdl SDL-ReleaseGPUFence
  (_fun _SDL_GPUDevice-pointer _SDL_GPUFence-pointer -> _void)
  #:c-id SDL_ReleaseGPUFence)

;; SDL_WaitForGPUFences: Wait for multiple fences
(define-sdl SDL-WaitForGPUFences
  (_fun _SDL_GPUDevice-pointer
        _sdl-bool  ; wait_all
        _pointer   ; SDL_GPUFence* const*
        _uint32    ; num_fences
        -> _sdl-bool)
  #:c-id SDL_WaitForGPUFences)

;; SDL_WaitForGPUIdle: Wait for all GPU work to complete
(define-sdl SDL-WaitForGPUIdle
  (_fun _SDL_GPUDevice-pointer -> _sdl-bool)
  #:c-id SDL_WaitForGPUIdle)

;; ============================================================================
;; Blit
;; ============================================================================

;; SDL_BlitGPUTexture: Blit between textures
(define-sdl SDL-BlitGPUTexture
  (_fun _SDL_GPUCommandBuffer-pointer _SDL_GPUBlitInfo-pointer -> _void)
  #:c-id SDL_BlitGPUTexture)
