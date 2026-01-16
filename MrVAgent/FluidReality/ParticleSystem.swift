import Metal
import MetalKit
import simd

/// High-performance particle system using Metal compute shaders
final class ParticleSystem {

    // MARK: - Particle Structure (matches Metal shader)

    struct Particle {
        var position: SIMD3<Float>
        var velocity: SIMD3<Float>
        var color: SIMD4<Float>
        var size: Float
        var life: Float           // 0.0 to 1.0
        var maxLife: Float        // seconds
        var rotation: Float

        static var zero: Particle {
            Particle(
                position: SIMD3<Float>(0, 0, 0),
                velocity: SIMD3<Float>(0, 0, 0),
                color: SIMD4<Float>(1, 1, 1, 1),
                size: 4.0,
                life: 0.0,
                maxLife: 1.0,
                rotation: 0.0
            )
        }
    }

    // MARK: - Uniforms

    struct ParticleUniforms {
        var time: Float
        var resolution: SIMD2<Float>
        var deltaTime: Float
        var projectionMatrix: simd_float4x4

        static var zero: ParticleUniforms {
            ParticleUniforms(
                time: 0,
                resolution: SIMD2<Float>(1280, 800),
                deltaTime: 0,
                projectionMatrix: matrix_identity_float4x4
            )
        }
    }

    // MARK: - Particle Types

    enum ParticleType {
        case ambient        // Slow floating background particles
        case thinking       // Burst when AI is processing
        case response       // Follow text as it appears
        case cursorTrail    // Trail behind cursor
        case mood           // Particles based on mood state

        var defaultColor: SIMD4<Float> {
            switch self {
            case .ambient:
                return SIMD4<Float>(0.7, 0.7, 0.8, 0.3)  // Soft white-blue
            case .thinking:
                return SIMD4<Float>(0.8, 0.6, 0.4, 0.6)  // Warm orange
            case .response:
                return SIMD4<Float>(0.6, 0.8, 0.6, 0.5)  // Soft green
            case .cursorTrail:
                return SIMD4<Float>(1.0, 1.0, 1.0, 0.4)  // White
            case .mood:
                return SIMD4<Float>(0.6, 0.4, 0.8, 0.4)  // Purple
            }
        }

        var defaultSize: Float {
            switch self {
            case .ambient:
                return 3.0
            case .thinking:
                return 5.0
            case .response:
                return 4.0
            case .cursorTrail:
                return 6.0
            case .mood:
                return 4.0
            }
        }

        var defaultLifetime: Float {
            switch self {
            case .ambient:
                return 8.0   // Long-lived
            case .thinking:
                return 2.0   // Burst effect
            case .response:
                return 3.0   // Medium
            case .cursorTrail:
                return 1.0   // Quick fade
            case .mood:
                return 5.0   // Medium-long
            }
        }
    }

    // MARK: - Metal Resources

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var particleBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var renderPipelineState: MTLRenderPipelineState?
    private var computePipelineState: MTLComputePipelineState?

    // MARK: - Particle State

    private var particles: [Particle] = []
    private let maxParticles: Int = 10_000
    private var activeParticleCount: Int = 0
    private var uniforms = ParticleUniforms.zero

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue

        setupBuffers()
        setupPipelines()
        initializeAmbientParticles()
    }

    private func setupBuffers() {
        // Allocate particle buffer
        let bufferSize = maxParticles * MemoryLayout<Particle>.stride
        particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)

        // Initialize with zero particles
        if let buffer = particleBuffer {
            let particles = buffer.contents().bindMemory(to: Particle.self, capacity: maxParticles)
            for i in 0..<maxParticles {
                particles[i] = Particle.zero
            }
        }

        // Allocate uniform buffer
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<ParticleUniforms>.stride,
            options: .storageModeShared
        )
    }

    private func setupPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create shader library")
            return
        }

        // Render pipeline
        if let vertexFunction = library.makeFunction(name: "particleVertexShader"),
           let fragmentFunction = library.makeFunction(name: "particleFragmentShader") {

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            // Enable blending for transparency
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            do {
                renderPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                print("Failed to create render pipeline: \(error)")
            }
        }

        // Compute pipeline
        if let computeFunction = library.makeFunction(name: "updateParticles") {
            do {
                computePipelineState = try device.makeComputePipelineState(function: computeFunction)
            } catch {
                print("Failed to create compute pipeline: \(error)")
            }
        }
    }

    private func initializeAmbientParticles() {
        // Create some ambient particles for background atmosphere
        for _ in 0..<50 {
            emit(
                at: CGPoint(
                    x: CGFloat(Float.random(in: 0...1280)),
                    y: CGFloat(Float.random(in: 0...800))
                ),
                count: 1,
                type: .ambient
            )
        }
    }

    // MARK: - Public Interface

    /// Emit particles at a position
    func emit(at position: CGPoint, count: Int, type: ParticleType) {
        guard let buffer = particleBuffer else { return }

        let particlesPtr = buffer.contents().bindMemory(to: Particle.self, capacity: maxParticles)

        for _ in 0..<count {
            // Find dead particle slot
            guard let index = findDeadParticleIndex(particlesPtr) else { continue }

            // Create new particle
            let angle = Float.random(in: 0...(2 * .pi))
            let speed = Float.random(in: 20...80)

            let velocity = SIMD3<Float>(
                cos(angle) * speed,
                sin(angle) * speed,
                0
            )

            var particle = Particle(
                position: SIMD3<Float>(Float(position.x), Float(position.y), 0),
                velocity: velocity,
                color: type.defaultColor,
                size: type.defaultSize,
                life: 1.0,
                maxLife: type.defaultLifetime,
                rotation: Float.random(in: 0...(2 * .pi))
            )

            // Type-specific adjustments
            switch type {
            case .ambient:
                particle.velocity.y *= 0.3  // Slower vertical
            case .thinking:
                particle.velocity *= 1.5     // Faster burst
            case .cursorTrail:
                particle.velocity *= 0.5     // Slow trail
            default:
                break
            }

            particlesPtr[index] = particle
            activeParticleCount += 1
        }
    }

    /// Update particle simulation
    func update(deltaTime: Float, viewSize: CGSize) {
        uniforms.deltaTime = deltaTime
        uniforms.time += deltaTime
        uniforms.resolution = SIMD2<Float>(Float(viewSize.width), Float(viewSize.height))

        // Update uniform buffer
        if let uniformBuffer = uniformBuffer {
            let uniformPtr = uniformBuffer.contents().bindMemory(to: ParticleUniforms.self, capacity: 1)
            uniformPtr[0] = uniforms
        }

        // Dispatch compute shader to update particles
        guard let computePipeline = computePipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(uniformBuffer, offset: 0, index: 1)

        let threadGroupSize = MTLSize(width: 64, height: 1, depth: 1)
        let threadGroups = MTLSize(
            width: (maxParticles + 63) / 64,
            height: 1,
            depth: 1
        )

        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()

        commandBuffer.commit()
    }

    /// Render particles
    func render(to renderEncoder: MTLRenderCommandEncoder) {
        guard let renderPipeline = renderPipelineState else { return }

        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        // Draw all particles as points
        renderEncoder.drawPrimitives(
            type: .point,
            vertexStart: 0,
            vertexCount: maxParticles
        )
    }

    // MARK: - Helpers

    private func findDeadParticleIndex(_ particles: UnsafeMutablePointer<Particle>) -> Int? {
        for i in 0..<maxParticles {
            if particles[i].life <= 0.0 {
                return i
            }
        }
        return nil
    }

    /// Get current active particle count
    var activeCount: Int {
        guard let buffer = particleBuffer else { return 0 }
        let particlesPtr = buffer.contents().bindMemory(to: Particle.self, capacity: maxParticles)

        var count = 0
        for i in 0..<maxParticles {
            if particlesPtr[i].life > 0.0 {
                count += 1
            }
        }
        return count
    }
}
