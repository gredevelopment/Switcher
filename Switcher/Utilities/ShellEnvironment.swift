import Foundation

enum ShellEnvironment {
    static func loginShellPath() -> String {
        if let shell = ProcessInfo.processInfo.environment["SHELL"], !shell.isEmpty {
            return shell
        }
        return "/bin/zsh"
    }

    static func augmentedPATH() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let extraPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/local/go/bin",
            "/opt/homebrew/opt/go/libexec/bin",
            "\(home)/go/bin",
            "\(home)/.cargo/bin",
            "\(home)/.local/bin",
            "\(home)/.npm-global/bin",
        ]

        let existing = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let components = (extraPaths + cachedLoginShellPATH + existing.split(separator: ":").map(String.init))
        var seen = Set<String>()
        let merged = components.filter { seen.insert($0).inserted }
        return merged.joined(separator: ":")
    }

    /// PATH from the user's login shell (matches Terminal for tools like `go` installed outside Homebrew).
    private static let cachedLoginShellPATH: [String] = {
        let shell = loginShellPath()
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", "printf %s \"$PATH\""]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env

        do {
            try process.run()
        } catch {
            return []
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let path = String(data: data, encoding: .utf8), !path.isEmpty else { return [] }
        return path.split(separator: ":").map(String.init)
    }()

    static func environment(workingDirectory: String? = nil) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = augmentedPATH()
        env["TERM"] = env["TERM"] ?? "xterm-256color"

        if let workingDirectory {
            env["PWD"] = workingDirectory
            env["INIT_CWD"] = workingDirectory
        }

        return env
    }

    static func portlessExecutablePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "/opt/homebrew/bin/portless",
            "/usr/local/bin/portless",
            "\(home)/.local/bin/portless",
            "\(home)/.npm-global/bin/portless",
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }

        return "portless"
    }
}
