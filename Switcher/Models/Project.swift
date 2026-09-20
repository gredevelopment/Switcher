import Foundation
import SwiftUI

enum ProjectIconStyle: String, Codable, CaseIterable {
    case symbol
    case image

    var label: String {
        switch self {
        case .symbol:
            "Icon"
        case .image:
            "Image"
        }
    }
}

struct Project: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var slug: String
    var directoryPath: String
    var runCommand: String
    var appPort: Int
    var iconName: String
    var iconColorHex: String
    var iconStyle: ProjectIconStyle
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        slug: String,
        directoryPath: String,
        runCommand: String,
        appPort: Int,
        iconName: String = IconCatalog.defaultIcon,
        iconColorHex: String = IconCatalog.defaultColorHex,
        iconStyle: ProjectIconStyle = .symbol,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.directoryPath = directoryPath
        self.runCommand = runCommand
        self.appPort = appPort
        self.iconName = iconName
        self.iconColorHex = iconColorHex
        self.iconStyle = iconStyle
        self.createdAt = createdAt
    }

    var iconColor: Color {
        Color(hex: iconColorHex) ?? Color(hex: IconCatalog.defaultColorHex)!
    }

    var localhostURL: URL {
        PortlessConfiguration.localhostURL(slug: slug)
    }

    var portlessCommand: String {
        PortlessConfiguration.portlessCommand(slug: slug, appPort: appPort, runCommand: runCommand)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, slug, directoryPath, runCommand, appPort, iconName, iconColorHex, iconStyle, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        directoryPath = try container.decode(String.self, forKey: .directoryPath)
        runCommand = try container.decode(String.self, forKey: .runCommand)
        appPort = try container.decodeIfPresent(Int.self, forKey: .appPort) ?? 0
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? IconCatalog.defaultIcon
        iconColorHex = try container.decodeIfPresent(String.self, forKey: .iconColorHex) ?? IconCatalog.defaultColorHex
        iconStyle = try container.decodeIfPresent(ProjectIconStyle.self, forKey: .iconStyle) ?? .symbol
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }
}

enum ProjectRunState: Equatable {
    case stopped
    case starting
    case running
    case stopping
    case crashed(exitCode: Int32)

    var isActive: Bool {
        switch self {
        case .starting, .running, .stopping:
            true
        case .stopped, .crashed:
            false
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isCrashed: Bool {
        if case .crashed = self { return true }
        return false
    }

    var statusLabel: String {
        switch self {
        case .stopped:
            "Stopped"
        case .starting:
            "Starting…"
        case .running:
            "Running"
        case .stopping:
            "Stopping…"
        case .crashed(let code):
            "Crashed (exit \(code))"
        }
    }
}
