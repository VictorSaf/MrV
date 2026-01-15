import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageRowView(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Auto-scroll to last message
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Error message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Dismiss") {
                        viewModel.errorMessage = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Message Mr.V...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .lineLimit(1...5)
                    .disabled(viewModel.isLoading)
                    .onSubmit {
                        if !viewModel.inputText.isEmpty {
                            viewModel.sendMessage()
                        }
                    }

                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.isLoading || viewModel.inputText.isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty && !viewModel.isLoading)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    viewModel.clearChat()
                }) {
                    Label("Clear Chat", systemImage: "trash")
                }
                .disabled(viewModel.messages.isEmpty)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))

            VStack(spacing: 8) {
                Text("Welcome to Mr.V")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your AI agent assistant powered by multiple models")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                suggestionButton("Explain quantum computing")
                suggestionButton("Write a Swift function")
                suggestionButton("Help me plan a project")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }

    private func suggestionButton(_ text: String) -> some View {
        Button(action: {
            viewModel.inputText = text
        }) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                Text(text)
                    .font(.subheadline)
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
}

// Preview removed for SPM compatibility
// Use Xcode for previews

