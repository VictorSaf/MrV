import Foundation
import SwiftUI
import Combine

/// Core orchestrator for the Fluid Reality system
/// Manages all fluid elements, their lifecycle, and interactions
@MainActor
final class FluidRealityEngine: ObservableObject {

    // MARK: - Published State

    @Published var activeElements: [FluidElement] = []
    @Published var voidState: VoidState = VoidState()
    @Published var timeState: TimeState = TimeState()

    // MARK: - Internal State

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 1.0 / 60.0  // 60 FPS

    // MARK: - Void State

    struct VoidState: Equatable {
        var isActive: Bool = false
        var breathingIntensity: Float = 0.3
        var baseColor: Color = Color(red: 0.05, green: 0.05, blue: 0.1)
        var cursorPosition: CGPoint = .zero
    }

    // MARK: - Time State

    struct TimeState: Equatable {
        var startTime: Date = Date()
        var currentTime: Date = Date()
        var elapsedTime: TimeInterval {
            currentTime.timeIntervalSince(startTime)
        }
    }

    // MARK: - Initialization

    init() {
        startVoid()
    }

    deinit {
        updateTimer?.invalidate()
    }

    // MARK: - Void Control

    func startVoid() {
        voidState.isActive = true
        timeState.startTime = Date()

        // Start update loop
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.update()
            }
        }
    }

    func stopVoid() {
        voidState.isActive = false
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Element Management

    /// Materialize a new element with birth animation
    func materializeElement(_ element: FluidElement) {
        var newElement = element
        newElement.lifecycle.phase = .birth
        newElement.lifecycle.birthTime = Date()
        newElement.lifecycle.age = 0

        activeElements.append(newElement)
    }

    /// Begin dissolving an element
    func dissolveElement(_ id: UUID, fulfilled: Bool = false) {
        if let index = activeElements.firstIndex(where: { $0.id == id }) {
            activeElements[index].beginDissolve(fulfilled: fulfilled)
        }
    }

    /// Remove element immediately (without animation)
    func removeElement(_ id: UUID) {
        activeElements.removeAll { $0.id == id }
    }

    /// Update all active elements
    private func update() async {
        let deltaTime = updateInterval
        timeState.currentTime = Date()

        var elementsToRemove: [UUID] = []

        // Update each element
        for index in activeElements.indices {
            activeElements[index].updateAge(deltaTime: deltaTime)

            // Mark completed dissolves for removal
            let element = activeElements[index]
            if (element.lifecycle.phase == .dissolving || element.lifecycle.phase == .fulfilled)
                && element.lifecycle.phaseProgress >= 1.0 {
                elementsToRemove.append(element.id)
            }
        }

        // Remove completed elements
        for id in elementsToRemove {
            removeElement(id)
        }
    }

    // MARK: - Void State Control

    func updateCursorPosition(_ position: CGPoint) {
        voidState.cursorPosition = position
    }

    func setBaseColor(_ color: Color) {
        voidState.baseColor = color
    }

    func setBreathingIntensity(_ intensity: Float) {
        voidState.breathingIntensity = intensity
    }

    // MARK: - Element Queries

    /// Get all text elements
    func textElements() -> [FluidElement] {
        activeElements.filter { $0.type.isText }
    }

    /// Get element by ID
    func element(withId id: UUID) -> FluidElement? {
        activeElements.first { $0.id == id }
    }

    /// Count of active (non-dissolving) elements
    var activeElementCount: Int {
        activeElements.filter { $0.lifecycle.phase == .active }.count
    }

    // MARK: - Positioning Helpers

    /// Calculate optimal position for new text element
    func calculateOptimalTextPosition(
        viewSize: CGSize,
        existingElements: [FluidElement]? = nil
    ) -> FluidElement.FluidPosition {
        let elements = existingElements ?? activeElements

        // Start from center-left
        let baseX = viewSize.width * 0.15
        let baseY = viewSize.height * 0.5

        // Offset based on number of existing text elements
        let textCount = elements.filter { $0.type.isText }.count
        let offsetY = CGFloat(textCount) * 60.0  // 60px vertical spacing

        return FluidElement.FluidPosition(
            x: baseX,
            y: baseY + offsetY,
            z: 0.0,  // Front layer
            opacity: 1.0,
            scale: 1.0,
            rotation: 0
        )
    }

    /// Calculate position for Mr.V symbol
    func calculateSymbolPosition(viewSize: CGSize) -> FluidElement.FluidPosition {
        // Top-right corner
        return FluidElement.FluidPosition(
            x: viewSize.width * 0.9,
            y: viewSize.height * 0.1,
            z: 0.2,  // Slightly back
            opacity: 0.8,
            scale: 1.0,
            rotation: 0
        )
    }

    // MARK: - Debug

    func printState() {
        print("=== Fluid Reality Engine State ===")
        print("Active: \(voidState.isActive)")
        print("Elements: \(activeElements.count)")
        print("  - Birth: \(activeElements.filter { $0.lifecycle.phase == .birth }.count)")
        print("  - Active: \(activeElementCount)")
        print("  - Dissolving: \(activeElements.filter { $0.lifecycle.phase == .dissolving }.count)")
        print("Elapsed time: \(timeState.elapsedTime)s")
        print("==================================")
    }
}
