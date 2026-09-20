import SwiftUI

struct LogsWindowView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let projectID: UUID

    private var project: Project? {
        store.projects.first { $0.id == projectID }
    }

    private var session: RunningProjectSession? {
        guard project != nil else { return nil }
        return store.session(for: projectID)
    }

    var body: some View {
        Group {
            if let project, let session {
                logsContent(project: project, session: session)
            } else {
                ContentUnavailableView("Project Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("\(project?.name ?? "Project") Logs")
    }

    @ViewBuilder
    private func logsContent(project: Project, session: RunningProjectSession) -> some View {
        VStack(spacing: 0) {
            header(project: project, session: session)
            Divider()
            logList(session: session)
        }
        .onExitCommand {
            dismiss()
        }
    }

    private func header(project: Project, session: RunningProjectSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.headline)
                Text(session.state.statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if session.state.isRunning {
                Button {
                    store.openInBrowser(project)
                } label: {
                    Label("Open", systemImage: "safari")
                }
            }

            Button {
                store.toggle(project)
            } label: {
                Label(
                    session.state.isActive ? "Stop" : "Start",
                    systemImage: session.state.isActive ? "stop.fill" : "play.fill"
                )
            }

            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.escape, modifiers: [])
            .help("Return to the project list")
        }
        .padding()
        .background(.bar)
    }

    private func logList(session: RunningProjectSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(session.logs) { line in
                        LogLineView(line: line)
                            .id(line.id)
                    }
                }
                .padding(12)
                .textSelection(.enabled)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: session.logs.count) { _, _ in
                if let last = session.logs.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct LogLineView: View {
    let line: LogLine

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(line.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 64, alignment: .leading)

            Text(line.stream == .stderr ? "ERR" : line.stream == .system ? "SYS" : "OUT")
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(streamColor)
                .frame(width: 28, alignment: .leading)

            Text(line.text.isEmpty ? " " : line.text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(line.stream == .stderr ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var streamColor: Color {
        switch line.stream {
        case .stderr:
            .red
        case .system:
            .orange
        case .stdout:
            .secondary
        }
    }
}
