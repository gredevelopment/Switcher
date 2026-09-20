import Foundation

enum PortlessProxyManager {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var startedProxyThisSession = false

    static func ensureRunning() throws {
        lock.lock()
        defer { lock.unlock() }

        if PortMonitor.isPortListening(PortlessConfiguration.proxyPort) {
            return
        }

        startedProxyThisSession = true
        let output = runShellCommand(PortlessConfiguration.proxyStartCommand())
        let normalized = output.lowercased()

        if normalized.contains("already running") {
            return
        }

        for _ in 0..<50 {
            if PortMonitor.isPortListening(PortlessConfiguration.proxyPort) {
                return
            }
            usleep(100_000)
        }

        if PortMonitor.isPortListening(PortlessConfiguration.proxyPort) {
            return
        }

        let details = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if details.isEmpty {
            throw PortlessProxyError.failedToStart(
                "Proxy did not start on port \(PortlessConfiguration.proxyPort). Is portless installed?"
            )
        }

        throw PortlessProxyError.failedToStart(details)
    }

    static func stopIfStartedByApp() {
        lock.lock()
        defer { lock.unlock() }

        guard startedProxyThisSession else { return }
        startedProxyThisSession = false

        let portless = ShellEnvironment.portlessExecutablePath()
        let command = "\(portless) proxy stop --port \(PortlessConfiguration.proxyPort)"
        _ = runShellCommand(command)
    }

    private static func runShellCommand(_ command: String) -> String {
        let process = Process()
        let shell = ShellEnvironment.loginShellPath()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-lc", command]
        process.environment = ShellEnvironment.environment()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return error.localizedDescription
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum PortlessProxyError: LocalizedError {
    case failedToStart(String)

    var errorDescription: String? {
        switch self {
        case .failedToStart(let details):
            if details.isEmpty {
                "Failed to start the portless proxy on port \(PortlessConfiguration.proxyPort)."
            } else {
                "Failed to start the portless proxy: \(details)"
            }
        }
    }
}
