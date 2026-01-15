import SwiftUI

struct MessageRowView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessageBubble
            } else {
                assistantMessageBubble
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var userMessageBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 400, alignment: .trailing)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }

    private var assistantMessageBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Mr.V")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if message.isStreaming {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .frame(width: 30)
                            .scaleEffect(0.5)
                    }
                }

                Text(message.content.isEmpty && message.isStreaming ? "Thinking..." : message.content)
                    .padding(12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                    .frame(maxWidth: 400, alignment: .leading)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews
