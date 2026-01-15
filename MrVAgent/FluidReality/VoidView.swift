import SwiftUI

/// Main void interface - abstract fluid reality system
struct VoidView: View {
    @EnvironmentObject var fluidReality: FluidRealityEngine
    @State private var cursorPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero

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
            }
            .preferredColorScheme(.dark)
            .onAppear {
                viewSize = geometry.size
            }
            .onChange(of: geometry.size) { newSize in
                viewSize = newSize
            }
        }
    }
}

/// Temporary placeholder for invisible input
/// Will be implemented in Pas 0.5
private struct InvisibleInputView: View {
    var body: some View {
        EmptyView()
    }
}
