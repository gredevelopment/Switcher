import Foundation

enum PortlessConfiguration {
    /// Unprivileged HTTPS proxy port — avoids sudo on port 443.
    static let proxyPort = 1355

    /// Fixed app ports assigned to each project (portless default range).
    static let appPortRange: ClosedRange<Int> = 4000...4999

    static func localhostURL(slug: String) -> URL {
        URL(string: "https://\(slug).localhost:\(proxyPort)")!
    }

    static func portlessCommand(slug: String, appPort: Int, runCommand: String) -> String {
        let portless = ShellEnvironment.portlessExecutablePath()
        let adaptedCommand = RunCommandAdapter.adapt(runCommand: runCommand, appPort: appPort)
        return "\(portless) \(slug) --app-port \(appPort) \(adaptedCommand)"
    }

    static func proxyStartCommand() -> String {
        let portless = ShellEnvironment.portlessExecutablePath()
        return "\(portless) proxy start --port \(proxyPort) --https"
    }
}
