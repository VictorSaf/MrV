import SwiftUI

/// Project selector view for switching between projects
struct ProjectSelectorView: View {
    @EnvironmentObject var consciousness: MrVConsciousness
    @Environment(\.dismiss) var dismiss

    @State private var projects: [ProjectMemoryStub] = []
    @State private var isCreatingNewProject = false
    @State private var newProjectName = ""
    @State private var newProjectDescription = ""
    @State private var selectedColor: Color = .blue
    @State private var error: String?

    var body: some View {
        ZStack {
            // Void background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Project list
                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }

                // New project section
                if isCreatingNewProject {
                    newProjectForm
                }

                Spacer()
            }
        }
        .task {
            await loadProjects()
        }
    }

    // MARK: - Components

    private var header: some View {
        HStack {
            Text("PROJECTS")
                .font(.system(size: 24, weight: .ultraLight, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .tracking(4)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .padding(.top, 30)
        .padding(.bottom, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.3))

            Text("No projects yet")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.6))

            Text("Create your first project to organize conversations")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            Button("Create Project") {
                withAnimation(.smooth) {
                    isCreatingNewProject = true
                }
            }
            .buttonStyle(VoidButtonStyle())
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var projectList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(projects) { project in
                    ProjectRow(
                        project: project,
                        isSelected: consciousness.currentProjectName == project.name
                    ) {
                        Task {
                            await selectProject(project)
                        }
                    }
                }

                // Create new button
                Button {
                    withAnimation(.smooth) {
                        isCreatingNewProject = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))

                        Text("New Project")
                            .font(.system(size: 14, weight: .light))

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
    }

    private var newProjectForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New Project")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Button {
                    withAnimation(.smooth) {
                        isCreatingNewProject = false
                        clearForm()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                TextField("Project name", text: $newProjectName)
                    .textFieldStyle(VoidTextFieldStyle())
            }

            // Description field
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (optional)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                TextField("What is this project about?", text: $newProjectDescription)
                    .textFieldStyle(VoidTextFieldStyle())
            }

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 12) {
                    ForEach([Color.blue, .purple, .green, .orange, .pink, .red], id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }

            // Error message
            if let error = error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
            }

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    withAnimation(.smooth) {
                        isCreatingNewProject = false
                        clearForm()
                    }
                }
                .buttonStyle(VoidButtonStyle(style: .secondary))

                Button("Create") {
                    Task {
                        await createProject()
                    }
                }
                .buttonStyle(VoidButtonStyle())
                .disabled(newProjectName.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func loadProjects() async {
        let memoryProjects = await consciousness.getProjects()
        projects = memoryProjects.map { proj in
            ProjectMemoryStub(id: proj.id, name: proj.name, status: "active")
        }
    }

    private func selectProject(_ project: ProjectMemoryStub) async {
        do {
            try await consciousness.switchProject(project.id)
            dismiss()
        } catch {
            self.error = "Failed to switch project: \(error.localizedDescription)"
        }
    }

    private func createProject() async {
        guard !newProjectName.isEmpty else { return }

        do {
            try await consciousness.createProject(name: newProjectName, description: newProjectDescription.isEmpty ? nil : newProjectDescription)

            withAnimation(.smooth) {
                isCreatingNewProject = false
                clearForm()
            }

            await loadProjects()
        } catch {
            self.error = "Failed to create project: \(error.localizedDescription)"
        }
    }

    private func clearForm() {
        newProjectName = ""
        newProjectDescription = ""
        selectedColor = .blue
        error = nil
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: ProjectMemoryStub
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status indicator
                Circle()
                    .fill(isSelected ? Color.green.opacity(0.8) : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)

                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                        .foregroundColor(.white.opacity(isSelected ? 1.0 : 0.8))

                    Text(project.status)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white.opacity(isSelected ? 0.2 : 0.0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        
    }
}

// MARK: - Custom Styles

struct VoidButtonStyle: ButtonStyle {
    enum Style {
        case primary, secondary
    }

    var style: Style = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(style == .primary ? .black : .white.opacity(0.8))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(style == .primary ? Color.white.opacity(configuration.isPressed ? 0.7 : 1.0) : Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct VoidTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.9))
            .padding(12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
    }
}

// MARK: - Stub Type (placeholder for actual ProjectMemory)

struct ProjectMemoryStub: Identifiable {
    let id: String
    let name: String
    let status: String
}
