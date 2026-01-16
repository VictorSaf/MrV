import SwiftUI

/// Mr.V presence symbol - minimal abstract representation
struct MrVSymbolView: View {
    @State private var pulsePhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    var accentColor: Color = .white

    var body: some View {
        ZStack {
            // Outer ring (breathing)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.3),
                            accentColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 60 + pulsePhase * 10, height: 60 + pulsePhase * 10)
                .blur(radius: 1 + pulsePhase * 2)

            // Inner symbol (abstract V)
            VShape()
                .stroke(accentColor.opacity(0.8), lineWidth: 2)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(rotationAngle))

            // Center dot
            Circle()
                .fill(accentColor.opacity(0.6 + pulsePhase * 0.3))
                .frame(width: 6, height: 6)
                .shadow(color: accentColor.opacity(0.5), radius: 4)
        }
        .onAppear {
            // Pulsing animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                pulsePhase = 1.0
            }

            // Slow rotation
            withAnimation(
                .linear(duration: 20.0)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }
}

/// Abstract V shape
private struct VShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Left stroke
        path.move(to: CGPoint(x: width * 0.2, y: 0))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.8))

        // Right stroke
        path.move(to: CGPoint(x: width * 0.8, y: 0))
        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.8))

        return path
    }
}
