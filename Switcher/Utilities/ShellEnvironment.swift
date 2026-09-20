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
            "\(home)/.local/bin",
            "\(home)/.npm-global/bin",
        ]

        let existing = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let components = (extraPaths + existing.split(separator: ":").map(String.init))
        var seen = Set<String>()
        let merged = components.filter { seen.insert($0).inserted }
        return merged.joined(separator: ":")
    }

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
