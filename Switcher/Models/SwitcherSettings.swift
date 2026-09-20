import Foundation

struct SwitcherSettings: Codable, Equatable {
    var schemaVersion: Int = 1

    static let `default` = SwitcherSettings()
}
