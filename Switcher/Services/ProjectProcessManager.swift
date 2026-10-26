import Foundation
import Observation

@MainActor
@Observable
final class RunningProjectSession {
    let projectID: UUID
    var state: ProjectRunState = .stopped
    private(set) var logs: [LogLine] = []
    private(set) var lastStartedAt: Date?
    private(set) var lastStoppedAt: Date?

    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var terminationObserver: NSObjectProtocol?

    init(projectID: UUID) {
        self.projectID = projectID
    }

    func start(project: Project) throws {
        guard !state.isActive else { return }

        state = .starting
        logs.removeAll(keepingCapacity: true)
        appendLog("Starting \(project.portlessCommand) in \(project.directoryPath)", stream: .system)

        let process = Process()
        let shell = ShellEnvironment.loginShellPath()
        process.executableURL = URL(fileURLWithPath: shell)
        // Use a non-login shell so ~/.zprofile side effects don't leak into project runs.
        process.arguments = ["-c", project.portlessCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: project.directoryPath, isDirectory: true)
        process.environment = ShellEnvironment.environment(
            workingDirectory: project.directoryPath
        )

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        terminationObserver = NotificationCenter.default.addObserver(
            forName: Process.didTerminateNotification,
            object: process,
            queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleTermination(process: process)
            }
        }

        do {
            try process.run()
        } catch {
            state = .crashed(exitCode: -1)
            appendLog("Failed to start process: \(error.localizedDescription)", stream: .stderr)
            cleanupProcessReferences()
            throw error
        }

        self.process = process
        self.stdoutPipe = stdout
        self.stderrPipe = stderr
        lastStartedAt = .now
        state = .running

        appendLog("Process started (PID \(process.processIdentifier))", stream: .system)
        appendLog("App port: \(project.appPort)", stream: .system)
        appendLog("URL: \(project.localhostURL.absoluteString)", stream: .system)

        readPipe(stdout, stream: .stdout)
        readPipe(stderr, stream: .stderr)
    }

    func stop() {
        guard let process, state.isActive else {
            state = .stopped
            return
        }

        state = .stopping
        appendLog("Stopping process…", stream: .system)
        let rootPID = process.processIdentifier
        terminateProcess(process, asynchronously: true)

        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            ProcessTreeTerminator.terminateTree(rootPID: rootPID)
        }
    }

    func stopAndWait(timeout: TimeInterval = 3) {
        guard state.isActive else {
            state = .stopped
            cleanupProcessReferences()
            return
        }

        state = .stopping
        appendLog("Stopping process…", stream: .system)
        stopPipeReaders()

        if let process {
            let rootPID = process.processIdentifier
            terminateProcess(process, asynchronously: false)
            ProcessTreeTerminator.terminateTree(rootPID: rootPID, timeout: timeout)

            if process.isRunning {
                process.interrupt()
                usleep(300_000)
            }

            if process.isRunning {
                process.terminate()
                usleep(200_000)
            }
        }

        lastStoppedAt = .now
        state = .stopped
        appendLog("Process stopped.", stream: .system)
        cleanupProcessReferences()
    }

    private func stopPipeReaders() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
    }

    private func terminateProcess(_ process: Process, asynchronously: Bool) {
        guard process.isRunning else { return }

        process.terminate()

        guard asynchronously else { return }

        let runningProcess = process
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            guard runningProcess.isRunning else { return }
            runningProcess.interrupt()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                if runningProcess.isRunning {
                    runningProcess.terminate()
                }
            }
        }
    }

    private func handleTermination(process: Process) {
        let code = process.terminationStatus
        lastStoppedAt = .now

        if state == .stopping || state == .stopped {
            state = .stopped
            appendLog("Process stopped.", stream: .system)
        } else {
            state = .crashed(exitCode: code)
            appendLog("Process exited with code \(code).", stream: .system)
        }

        cleanupProcessReferences()
    }

    private func cleanupProcessReferences() {
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
            self.terminationObserver = nil
        }
        process = nil
        stdoutPipe = nil
        stderrPipe = nil
    }

    private func readPipe(_ pipe: Pipe, stream: LogStream) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            guard let text = String(data: data, encoding: .utf8) else { return }

            DispatchQueue.main.async {
                self?.appendLog(text, stream: stream)
            }
        }
    }

    var lastErrorSummary: String? {
        guard case .crashed = state else { return nil }

        let meaningful = logs.filter { line in
            !line.text.isEmpty && line.displayKind == .error
        }

        if let last = meaningful.last {
            return last.text
        }

        if case .crashed(let code) = state {
            return "Server failed to start (exit \(code)). Open logs for details."
        }

        return "Server failed to start. Open logs for details."
    }

    var hasLogs: Bool {
        !logs.isEmpty
    }

    func appendSystemLog(_ text: String) {
        appendLog(text, stream: .system)
    }

    private func appendLog(_ text: String, stream: LogStream) {
        let pieces = text.split(separator: "\n", omittingEmptySubsequences: false)
        for piece in pieces {
            let line = String(piece)
            if line.isEmpty && stream != .system { continue }
            logs.append(LogLine(timestamp: .now, stream: stream, text: line))
        }

        if logs.count > 5_000 {
            logs.removeFirst(logs.count - 5_000)
        }
    }
}

struct LogLine: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let stream: LogStream
    let text: String
}

enum LogStream: String {
    case stdout
    case stderr
    case system
}
