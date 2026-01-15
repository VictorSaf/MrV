import SwiftUI

/// Main void interface - abstract fluid reality system
struct VoidView: View {
    @EnvironmentObject var fluidReality: FluidRealityEngine
    @StateObject private var consciousness: MrVConsciousness
    @State private var cursorPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero

    init() {
        // Initialize consciousness (will be connected to fluidReality in onAppear)
        _consciousness = StateObject(wrappedValue: MrVConsciousness())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Metal background (breathing void)
                MetalView(cursorPosition: $cursorPosition)
                    .ignoresSafeArea()

                // Fluid elements layer
                ForEach(fluidReality.activeElements) { element in
                    FluidElementView(element: element)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Mr.V symbol (top-right)
                VStack {
                    HStack {
                        Spacer()
                        MrVSymbolView()
                            .padding(.top, 30)
                            .padding(.trailing, 30)
                    }
                    Spacer()
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
            }
            .onChange(of: geometry.size) { newSize in
                viewSize = newSize
            }
        }
    }
}

// InvisibleInputView now imported from Input/InvisibleInput.swift
