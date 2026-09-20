import SwiftUI

struct ProjectRowView: View {
    @Environment(ProjectStore.self) private var store

    let project: Project
    var isEditingList = false
    var isSelected = false
    var onToggleSelection: (() -> Void)?
    let onEdit: () -> Void

    var body: some View {
        ProjectRowContent(
            project: project,
            session: store.session(for: project.id),
            isEditingList: isEditingList,
            isSelected: isSelected,
            onToggleSelection: onToggleSelection,
            onEdit: onEdit
        )
    }
}

private struct ProjectRowContent: View {
    @Environment(ProjectStore.self) private var store

    let project: Project
    @Bindable var session: RunningProjectSession
    let isEditingList: Bool
    let isSelected: Bool
    let onToggleSelection: (() -> Void)?
    let onEdit: () -> Void

    @State private var showingLogs = false

    var body: some View {
        HStack(spacing: 14) {
            if isEditingList {
                Button {
                    onToggleSelection?()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(isSelected ? "Deselect project" : "Select project")
            }

            ProjectIconTile(project: project, isActive: session.state.isActive)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ProjectTypeLogo(type: project.detectedType)
                        .help(project.detectedType.label)

                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    StatusBadge(state: session.state)
                    Text(verbatim: ":\(project.appPort)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(project.directoryPath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            if !isEditingList {
                HStack(spacing: 4) {
                    if session.state.isRunning || session.state.isCrashed {
                        IconActionButton(
                            systemImage: "doc.text",
                            help: session.state.isCrashed ? "View logs" : "View live logs",
                            size: 26,
                            iconSize: 12
                        ) {
                            showingLogs = true
                        }
                    }

                    if session.state.isRunning {
                        IconActionButton(
                            systemImage: "safari",
                            help: "Open in browser",
                            size: 26,
                            iconSize: 12
                        ) {
                            store.openInBrowser(project)
                        }
                    }

                    IconActionButton(
                        systemImage: "gearshape",
                        help: "Edit project",
                        size: 26,
                        iconSize: 12
                    ) {
                        onEdit()
                    }

                    Toggle(isOn: Binding(
                        get: { session.state.isActive },
                        set: { shouldRun in
                            if shouldRun {
                                store.start(project)
                            } else {
                                store.stop(project)
                            }
                        }
                    )) {
                        EmptyView()
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .focusable(false)
                    .help(session.state.isActive ? "Stop server" : "Start server")
                }
            }
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showingLogs) {
            LogsWindowView(projectID: project.id)
                .environment(store)
                .frame(minWidth: 640, minHeight: 420)
        }
        .onChange(of: session.state) { _, newState in
            if newState.isCrashed {
                showingLogs = true
            }
        }
    }

}

private struct StatusBadge: View {
    let state: ProjectRunState

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(state.statusLabel)
                .font(.caption)
                .foregroundStyle(state.isCrashed ? .red : .secondary)
        }
    }

    private var color: Color {
        switch state {
        case .running:
            .green
        case .starting, .stopping:
            .orange
        case .crashed:
            .red
        case .stopped:
            .secondary
        }
    }
}
