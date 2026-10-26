import Foundation

enum LogDisplayKind: Equatable {
    case output
    case warning
    case error
    case system
}

enum LogLineClassifier {
    /// Rust/Cargo and similar tools log normal progress on stderr.
    private static let toolchainProgress = try! NSRegularExpression(
        pattern: #"^\s*(Compiling|Finished|Running|Fresh|Downloading|Updating|Documenting|Checking|Built|Installing|Generated|Blocking|Created|Identified|Resolved|Crate|Launching)\b"#,
        options: []
    )

    private static let warningPattern = try! NSRegularExpression(
        pattern: #"\bwarning(\[|:)"#,
        options: [.caseInsensitive]
    )

    static func displayKind(stream: LogStream, text: String) -> LogDisplayKind {
        switch stream {
        case .stdout:
            return .output
        case .system:
            return .system
        case .stderr:
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return .output
            }
            if isToolchainProgress(trimmed) {
                return .output
            }
            if isWarning(trimmed) {
                return .warning
            }
            return .error
        }
    }

    static func displayTag(kind: LogDisplayKind) -> String {
        switch kind {
        case .output:
            "OUT"
        case .warning:
            "WRN"
        case .error:
            "ERR"
        case .system:
            "SYS"
        }
    }

    private static func isToolchainProgress(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return toolchainProgress.firstMatch(in: text, options: [], range: range) != nil
    }

    private static func isWarning(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return warningPattern.firstMatch(in: text, options: [], range: range) != nil
    }
}

extension LogLine {
    var displayKind: LogDisplayKind {
        LogLineClassifier.displayKind(stream: stream, text: text)
    }

    var displayTag: String {
        LogLineClassifier.displayTag(kind: displayKind)
    }
}
