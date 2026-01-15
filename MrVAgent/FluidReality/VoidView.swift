import SwiftUI

/// Main void interface - abstract fluid reality system
struct VoidView: View {
    @EnvironmentObject var fluidReality: FluidRealityEngine
    @StateObject private var consciousness: MrVConsciousness
    @State private var cursorPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero
    @State private var currentTheme: UniverseTheme = .void

    init() {
        // Initialize consciousness (will be connected to fluidReality in onAppear)
        _consciousness = StateObject(wrappedValue: MrVConsciousness())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Metal background (breathing void) - responds to theme
                MetalView(
                    cursorPosition: $cursorPosition,
                    backgroundColor: currentTheme.colors.background.color,
                    primaryColor: currentTheme.colors.primary.color,
                    breathingIntensity: Float(currentTheme.effects.breathing.intensity)
                )
                    .ignoresSafeArea()

                // Fluid elements layer
                ForEach(fluidReality.activeElements) { element in
                    FluidElementView(element: element)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Mr.V symbol (top-right) - adapts to theme
                VStack {
                    HStack {
                        Spacer()
                        MrVSymbolView(accentColor: currentTheme.colors.accent.color)
                            .padding(.top, 30)
                            .padding(.trailing, 30)
                    }
                    Spacer()
                }

                // Universe transition indicator (when transitioning)
                if consciousness.getUniverseManager().isTransitioning {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Entering \(consciousness.currentUniverse.name)...")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(currentTheme.colors.text.color.opacity(0.6))
                                .padding()
                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                }

                // Invisible input (handled separately)
                InvisibleInputView()
                    .environmentObject(consciousness)
            }
            .preferredColorScheme(.dark)
            .onAppear {
                viewSize = geometry.size
                // Connect consciousness to fluid reality
                consciousness.setFluidReality(fluidReality)
                // Set initial theme
                currentTheme = consciousness.currentUniverse
            }
            .onChange(of: geometry.size) { newSize in
                viewSize = newSize
            }
            .onChange(of: consciousness.currentUniverse) { newUniverse in
                // Animate theme change
                withAnimation(.easeInOut(duration: 1.5)) {
                    currentTheme = newUniverse
                }
            }
        }
    }
}

// InvisibleInputView now imported from Input/InvisibleInput.swift
