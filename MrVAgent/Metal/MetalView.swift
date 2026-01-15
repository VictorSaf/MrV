import SwiftUI
import MetalKit

/// SwiftUI wrapper for MTKView
/// Provides Metal rendering surface for the Fluid Reality interface
struct MetalView: NSViewRepresentable {

    @Binding var cursorPosition: CGPoint

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = TrackingMTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.framebufferOnly = true
        mtkView.clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0)
        mtkView.coordinator = context.coordinator

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update cursor position in coordinator
        context.coordinator.cursorPosition = cursorPosition
    }

    // MARK: - Custom MTKView with Mouse Tracking

    class TrackingMTKView: MTKView {
        weak var coordinator: Coordinator?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            trackingAreas.forEach { removeTrackingArea($0) }

            let trackingArea = NSTrackingArea(
                rect: bounds,
                options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
        }

        override func mouseMoved(with event: NSEvent) {
            let locationInView = convert(event.locationInWindow, from: nil)
            coordinator?.updateCursorPosition(locationInView)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        let renderer: MetalRenderer
        var cursorPosition: CGPoint = .zero
        private var lastUpdateTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

        init(_ parent: MetalView) {
            self.parent = parent
            self.renderer = MetalRenderer()
            super.init()
        }

        func updateCursorPosition(_ position: CGPoint) {
            cursorPosition = position
            DispatchQueue.main.async {
                self.parent.cursorPosition = position
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize
        }

        func draw(in view: MTKView) {
            let currentTime = CFAbsoluteTimeGetCurrent()
            let deltaTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime

            // Update renderer state
            renderer.update(
                deltaTime: deltaTime,
                viewSize: view.drawableSize,
                cursorPosition: cursorPosition
            )

            // Render frame
            renderer.render(to: view)
        }
    }
}

// MARK: - Preview Helper

extension MetalView {
    /// Create a MetalView with default state binding for previews
    static func preview() -> MetalView {
        MetalView(cursorPosition: .constant(.zero))
    }
}
