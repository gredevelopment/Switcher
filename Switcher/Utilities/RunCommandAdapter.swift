import Foundation

enum ProjectFramework: String, CaseIterable, Identifiable, Equatable {
    case standard
    case nextjs
    case mintlify
    case reactNative
    case astro
    case nuxt
    case remix
    case svelte
    case vite
    case angular
    case laravel

    var id: String { rawValue }

    static var selectableCases: [ProjectFramework] {
        [.standard] + allCases.filter { $0 != .standard }
    }

    var label: String {
        switch self {
        case .standard:
            "Standard"
        case .nextjs:
            "Next.js"
        case .mintlify:
            "Mintlify"
        case .reactNative:
            "React Native"
        case .astro:
            "Astro"
        case .nuxt:
            "Nuxt"
        case .remix:
            "Remix"
        case .svelte:
            "SvelteKit"
        case .vite:
            "Vite"
        case .angular:
            "Angular"
        case .laravel:
            "Laravel"
        }
    }

    var assetName: String? {
        switch self {
        case .standard:
            "FrameworkNodeJS"
        case .nextjs:
            "FrameworkNextJS"
        case .mintlify:
            "FrameworkMintlify"
        case .reactNative:
            "FrameworkReactNative"
        case .astro:
            "FrameworkAstro"
        case .nuxt:
            "FrameworkNuxt"
        case .remix:
            "FrameworkRemix"
        case .svelte:
            "FrameworkSvelte"
        case .vite:
            "FrameworkVite"
        case .angular:
            "FrameworkAngular"
        case .laravel:
            "FrameworkLaravel"
        }
    }

    var defaultCommand: String {
        switch self {
        case .standard, .nextjs, .astro, .nuxt, .remix, .svelte, .vite:
            "npm run dev"
        case .mintlify:
            "mint dev"
        case .reactNative:
            "npx react-native start --reset-cache"
        case .angular:
            "ng serve"
        case .laravel:
            "php artisan serve"
        }
    }
}

enum RunCommandAdapter {
    static func detectedFramework(for command: String) -> ProjectFramework {
        let lowered = command.lowercased()

        if isMintlifyCommand(command) {
            return .mintlify
        }
        if isReactNativeCommand(command) {
            return .reactNative
        }
        if lowered.contains("next") {
            return .nextjs
        }
        if lowered.contains("astro") {
            return .astro
        }
        if lowered.contains("nuxt") {
            return .nuxt
        }
        if lowered.contains("remix") {
            return .remix
        }
        if lowered.contains("svelte") {
            return .svelte
        }
        if lowered.contains("ng serve") {
            return .angular
        }
        if lowered.contains("artisan serve") {
            return .laravel
        }
        if lowered.contains("vite") {
            return .vite
        }

        return .standard
    }

    static func adapt(runCommand: String, appPort: Int, framework: ProjectFramework = .standard) -> String {
        let trimmed = runCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedFramework = framework == .standard ? detectedFramework(for: trimmed) : framework

        if resolvedFramework == .mintlify {
            return adaptMintlify(trimmed, appPort: appPort)
        }

        return trimmed
    }

    static func isMintlifyCommand(_ command: String) -> Bool {
        let pattern = #"(?:^|\s)(?:npx\s+)?(?:mintlify|mint)(?:\s|$)"#
        return command.range(of: pattern, options: .regularExpression) != nil
    }

    static func isReactNativeCommand(_ command: String) -> Bool {
        let pattern = #"(?:^|\s)(?:npx\s+)?react-native(?:\s|$)"#
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
