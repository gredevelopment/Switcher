import Foundation

enum ProjectFramework: String, CaseIterable, Identifiable {
    case auto
    case mintlify
    case standard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto:
            "Auto-detect"
        case .mintlify:
            "Mintlify"
        case .standard:
            "Standard"
        }
    }

    var defaultCommand: String {
        switch self {
        case .auto, .standard:
            "npm run dev"
        case .mintlify:
            "mint dev"
        }
    }
}

enum RunCommandAdapter {
    static func detectedFramework(for command: String) -> ProjectFramework {
        if isMintlifyCommand(command) {
            return .mintlify
        }
        return .standard
    }

    static func adapt(runCommand: String, appPort: Int, framework: ProjectFramework = .auto) -> String {
        let trimmed = runCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedFramework = framework == .auto ? detectedFramework(for: trimmed) : framework

        switch resolvedFramework {
        case .mintlify:
            return adaptMintlify(trimmed, appPort: appPort)
        case .auto, .standard:
            return trimmed
        }
    }

    static func isMintlifyCommand(_ command: String) -> Bool {
        let pattern = #"(?:^|\s)(?:npx\s+)?(?:mintlify|mint)(?:\s|$)"#
        return command.range(of: pattern, options: .regularExpression) != nil
    }

    private static func adaptMintlify(_ command: String, appPort: Int) -> String {
        var parts: [String] = []

        if !containsFlag(command, name: "port") {
            parts.append("--port \(appPort)")
        }

        if !containsFlag(command, name: "no-open") && !containsFlag(command, name: "open") {
            parts.append("--no-open")
        }

        guard !parts.isEmpty else { return command }
        return "\(command) \(parts.joined(separator: " "))"
    }

    private static func containsFlag(_ command: String, name: String) -> Bool {
        let pattern = "--\(name)(?:\\s|=|$)"
        return command.range(of: pattern, options: .regularExpression) != nil
    }
}
