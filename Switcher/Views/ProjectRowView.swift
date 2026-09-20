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
    @Environment(\.colorScheme) private var colorScheme

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
                .help(isSelected ? "Deselect project" : "Select project")
            }

            projectIcon

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if project.detectedType != .unknown {
                        ProjectTypeLogo(type: project.detectedType)
                            .help(project.detectedType.label)
                    }

                    Text(project.name)
                        .font(.headline)
                }

                HStack(spacing: 8) {
                    StatusBadge(state: session.state)
                    Text(verbatim: ":\(project.appPort)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if session.state.isRunning {
                        Text(project.localhostURL.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                if session.state.isCrashed {
                    VStack(alignment: .leading, spacing: 6) {
                        if let errorSummary = session.lastErrorSummary {
                            Text(errorSummary)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(3)
                                .textSelection(.enabled)
                        }

                        Button {
                            showingLogs = true
                        } label: {
                            Label("View Logs", systemImage: "doc.text.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Text(project.directoryPath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)

            if !isEditingList {
                HStack(spacing: 8) {
                    if session.state.isRunning {
                        Button {
                            showingLogs = true
                        } label: {
                            Label("Logs", systemImage: "doc.text")
                        }
                        .buttonStyle(.borderless)
                        .help("View live logs")

                        Button {
                            store.openInBrowser(project)
                        } label: {
                            Label("Open", systemImage: "safari")
                        }
                        .buttonStyle(.borderless)
                        .help("Open in browser")
                    }

                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help("Edit project")

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

    private var projectIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(project.iconColor.opacity(session.state.isActive ? 0.2 : 0.12))
                .frame(width: 44, height: 44)

            Image(systemName: project.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(iconForegroundColor)
        }
    }

    private var iconForegroundColor: Color {
        if session.state.isCrashed {
            return Color.red.iconGlyph(colorScheme: colorScheme)
        }
        return project.iconColor.iconGlyph(
            colorScheme: colorScheme,
            muted: !session.state.isActive
        )
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
