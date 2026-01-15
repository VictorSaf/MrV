import SwiftUI

/// Invisible input system - captures keyboard without visible UI
/// Text appears subtly as user types, disappears on submit
struct InvisibleInputView: View {
    @EnvironmentObject var fluidReality: FluidRealityEngine
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    @State private var showInputIndicator: Bool = false

    var body: some View {
        ZStack {
            // Completely invisible TextField
            TextField("", text: $inputText)
                .opacity(0)
                .frame(width: 1, height: 1)
                .focused($isFocused)
                .onSubmit {
                    handleSubmit()
                }
                .onChange(of: inputText) { newValue in
                    showInputIndicator = !newValue.isEmpty
                }

            // Subtle input indicator (only when typing)
            if showInputIndicator && !inputText.isEmpty {
                inputIndicatorView
            }
        }
        .onAppear {
            // Auto-focus on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }

    // MARK: - Input Indicator

    private var inputIndicatorView: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Text(inputText)
                        .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .blur(radius: 1)
                        .padding(.bottom, 60)
                        .padding(.trailing, 40)

                    // Blinking cursor
                    Text("|")
                        .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .opacity(cursorOpacity)
                        .padding(.bottom, 60)
                        .padding(.trailing, 40)
                        .onAppear {
                            startCursorBlink()
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Cursor Animation

    @State private var cursorOpacity: Double = 1.0

    private func startCursorBlink() {
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            cursorOpacity = 0.0
        }
    }

    // MARK: - Input Handling

    private func handleSubmit() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Process input (will be connected to MrV Consciousness in Pas 0.7)
        processInput(text)

        // Clear input
        inputText = ""
        showInputIndicator = false

        // Maintain focus
        isFocused = true
    }

    private func processInput(_ text: String) {
        // Create fluid element for user input
        let userElement = FluidElement(
            type: .text(text),
            position: fluidReality.calculateOptimalTextPosition(
                viewSize: CGSize(width: 1280, height: 800)
            ),
            content: .text(text),
            style: FluidElement.ElementStyle(
                font: .system(size: 18, weight: .light),
                foregroundColor: .white.opacity(0.9),
                glowIntensity: 0.2
            )
        )

        fluidReality.materializeElement(userElement)

        // TODO: Send to MrV Consciousness (Pas 0.7)
        // For now, just echo back
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            createEchoResponse(for: text)
        }
    }

    // Temporary echo response (until Pas 0.7)
    private func createEchoResponse(for input: String) {
        let responseElement = FluidElement(
            type: .text("Echo: \(input)"),
            position: FluidElement.FluidPosition(
                x: fluidReality.voidState.cursorPosition.x,
                y: fluidReality.voidState.cursorPosition.y + 50,
                z: 0.1,
                opacity: 1.0,
                scale: 1.0,
                rotation: 0
            ),
            content: .text("Echo: \(input)"),
            style: FluidElement.ElementStyle(
                font: .system(size: 16, weight: .light),
                foregroundColor: .blue.opacity(0.8),
                glowIntensity: 0.3
            )
        )

        fluidReality.materializeElement(responseElement)

        // Auto-dissolve after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            fluidReality.dissolveElement(responseElement.id)
        }
    }
}

// MARK: - Keyboard Shortcuts

extension InvisibleInputView {
    /// Add keyboard shortcuts for void control
    private func handleKeyboardShortcuts() {
        // Command+K: Clear all elements
        // Command+Escape: Dissolve all elements
        // Command+/: Show help (future)
    }
}
