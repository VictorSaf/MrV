import Metal
import MetalKit
import simd

/// Core Metal rendering engine for Mr.V Agent
/// Manages GPU resources and rendering pipeline
final class MetalRenderer: NSObject {

    // MARK: - Metal Resources

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var startTime: CFAbsoluteTime
    private var particleSystem: ParticleSystem?

    // MARK: - Uniforms

    struct BackgroundUniforms {
        var time: Float
        var resolution: SIMD2<Float>
        var cursorPosition: SIMD2<Float>
        var baseColor: SIMD3<Float>
        var breathingIntensity: Float
        var noiseScale: Float
    }

    private var uniforms = BackgroundUniforms(
        time: 0,
        resolution: SIMD2<Float>(1280, 720),
        cursorPosition: SIMD2<Float>(0.5, 0.5),
        baseColor: SIMD3<Float>(0.05, 0.05, 0.1), // Deep blue-black
        breathingIntensity: 0.3,
        noiseScale: 1.0
    )

    // MARK: - Initialization

    override init() {
        // Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device

        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create Metal command queue")
        }
        self.commandQueue = commandQueue

        self.startTime = CFAbsoluteTimeGetCurrent()

        super.init()

        setupPipeline()
        setupParticleSystem()
    }

    // MARK: - Pipeline Setup

    private func setupParticleSystem() {
        particleSystem = ParticleSystem(device: device, commandQueue: commandQueue)
    }

    private func setupPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load Metal shader library")
        }

        guard let vertexFunction = library.makeFunction(name: "backgroundVertexShader"),
              let fragmentFunction = library.makeFunction(name: "backgroundFragmentShader") else {
            fatalError("Could not load shader functions")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    // MARK: - Public Interface

    /// Update uniforms for next frame
    func update(deltaTime: Double, viewSize: CGSize, cursorPosition: CGPoint) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        uniforms.time = Float(currentTime - startTime)
        uniforms.resolution = SIMD2<Float>(Float(viewSize.width), Float(viewSize.height))

        // Normalize cursor position to 0-1 range
        uniforms.cursorPosition = SIMD2<Float>(
            Float(cursorPosition.x / viewSize.width),
            Float(cursorPosition.y / viewSize.height)
        )

        // Update particle system
        particleSystem?.update(deltaTime: Float(deltaTime), viewSize: viewSize)
    }

    /// Update base color (for mood changes)
    func setBaseColor(r: Float, g: Float, b: Float) {
        uniforms.baseColor = SIMD3<Float>(r, g, b)
    }

    /// Update breathing intensity
    func setBreathingIntensity(_ intensity: Float) {
        uniforms.breathingIntensity = intensity
    }

    // MARK: - Rendering

    /// Render a frame
    func render(to view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        // Clear color (deep void)
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.02,
            green: 0.02,
            blue: 0.05,
            alpha: 1.0
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        // Pass uniforms to shader
        var uniformsData = uniforms
        renderEncoder.setFragmentBytes(&uniformsData,
                                       length: MemoryLayout<BackgroundUniforms>.stride,
                                       index: 0)

        // Draw fullscreen quad (triangle strip with 4 vertices)
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                     vertexStart: 0,
                                     vertexCount: 4)

        // Render particles on top of background
        particleSystem?.render(to: renderEncoder)

        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Particle Control

    /// Emit particles at a specific position
    func emitParticles(at position: CGPoint, count: Int, type: ParticleSystem.ParticleType) {
        particleSystem?.emit(at: position, count: count, type: type)
    }

    /// Get active particle count
    var activeParticleCount: Int {
        particleSystem?.activeCount ?? 0
    }
}
