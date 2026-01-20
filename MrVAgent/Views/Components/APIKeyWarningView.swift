import SwiftUI

/// Warning indicator shown when no API keys are configured
/// Integrates with UniverseTheme for consistent styling
struct APIKeyWarningView: View {
    let theme: UniverseTheme

    var body: some View {
        VStack {
            Spacer()
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(theme.colors.accent.color.opacity(0.7))

                    Text("No API keys configured - Press ⌘, for Settings")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(theme.colors.text.color.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.colors.background.color.opacity(0.3))
                )
                .padding(.leading, 20)
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }
}
