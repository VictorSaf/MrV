import SwiftUI

/// Main void interface - abstract fluid reality system
struct VoidView: View {
    @EnvironmentObject var fluidReality: FluidRealityEngine
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var consciousness: MrVConsciousness
    @State private var cursorPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero
    @State private var currentTheme: UniverseTheme = .void
    @State private var showAPIKeyWarning = false

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

                // API Key warning indicator (bottom-left, theme-aware)
                if showAPIKeyWarning {
                    APIKeyWarningView(theme: currentTheme)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                viewSize = geometry.size
                // Connect consciousness to fluid reality
                consciousness.setFluidReality(fluidReality)
                // Set initial theme
                currentTheme = consciousness.currentUniverse
                // Check API keys configuration
                checkAPIKeysConfigured()
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
            .sheet(isPresented: $settingsManager.showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Helper Methods

    private func checkAPIKeysConfigured() {
        let keychainService = KeychainService.shared
        let hasAnyKey = AIProvider.allCases.contains { provider in
            provider.requiresAPIKey && keychainService.apiKeyExists(for: provider.rawValue)
        }
        showAPIKeyWarning = !hasAnyKey
    }
}

// InvisibleInputView now imported from Input/InvisibleInput.swift
