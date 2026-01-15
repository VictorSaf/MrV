import SwiftUI

/// SwiftUI view for rendering a single fluid element
struct FluidElementView: View {
    let element: FluidElement

    var body: some View {
        Group {
            switch element.type {
            case .text(let text):
                textView(text)
            case .symbol:
                symbolView()
            case .particle:
                particleView()
            case .interface:
                interfaceView()
            }
        }
        .opacity(element.currentOpacity())
        .scaleEffect(element.currentScale())
        .blur(radius: element.currentBlur())
        .rotationEffect(.degrees(Double(element.position.rotation)))
        .position(x: element.position.x, y: element.position.y)
    }

    // MARK: - Element Type Views

    private func textView(_ text: String) -> some View {
        Group {
            switch element.content {
            case .text(let content):
                Text(content)
                    .font(element.style.font)
                    .foregroundColor(element.style.foregroundColor)
            case .attributedText(let attributed):
                Text(attributed)
                    .foregroundColor(element.style.foregroundColor)
            default:
                Text(text)
                    .font(element.style.font)
                    .foregroundColor(element.style.foregroundColor)
            }
        }
        .shadow(color: element.style.foregroundColor.opacity(element.style.glowIntensity),
                radius: element.style.glowIntensity * 10)
    }

    private func symbolView() -> some View {
        Group {
            if case .symbol(let name) = element.content {
                Image(systemName: name)
                    .font(.system(size: 24))
                    .foregroundColor(element.style.foregroundColor)
            } else {
                EmptyView()
            }
        }
    }

    private func particleView() -> some View {
        Circle()
            .fill(element.style.foregroundColor)
            .frame(width: 4, height: 4)
    }

    private func interfaceView() -> some View {
        EmptyView()  // Custom interface elements handled separately
    }
}
