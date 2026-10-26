import Foundation

enum ProjectTypeDetector {
    static func detect(directoryPath: String, runCommand: String) -> ProjectFramework {
        let directory = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let command = runCommand.lowercased()
        let packageJSON = loadPackageJSON(at: directory)
        let dependencies = dependencyNames(in: packageJSON)

        if RunCommandAdapter.isMintlifyCommand(runCommand)
            || fileExists(named: "mint.json", in: directory)
            || dependencies.contains("mintlify") {
            return .mintlify
        }

        if command.contains("next")
            || hasNextConfig(in: directory)
            || dependencies.contains("next") {
            return .nextjs
        }

        if RunCommandAdapter.isReactNativeCommand(runCommand)
            || fileExists(named: "react-native.config.js", in: directory)
            || dependencies.contains("react-native") {
            return .reactNative
        }

        if command.contains("astro")
            || hasConfig(matching: "astro.config", in: directory)
            || dependencies.contains(where: { $0.hasPrefix("@astrojs/") || $0 == "astro" }) {
            return .astro
        }

        if command.contains("nuxt")
            || hasConfig(matching: "nuxt.config", in: directory)
            || dependencies.contains("nuxt")
            || dependencies.contains("nuxt3") {
            return .nuxt
        }

        if command.contains("remix")
            || dependencies.contains("@remix-run/react")
            || dependencies.contains("@remix-run/dev") {
            return .remix
        }

        if command.contains("svelte")
            || hasConfig(matching: "svelte.config", in: directory)
            || dependencies.contains("@sveltejs/kit") {
            return .svelte
        }

        if command.contains("ng serve")
            || fileExists(named: "angular.json", in: directory)
            || dependencies.contains("@angular/core") {
            return .angular
        }

        if command.contains("artisan serve")
            || fileExists(named: "artisan", in: directory)
            || composerRequiresLaravel(in: directory) {
            return .laravel
        }

        if command.contains("vite")
            || hasConfig(matching: "vite.config", in: directory)
            || dependencies.contains("vite") {
            return .vite
        }

        if RunCommandAdapter.isRustCommand(runCommand)
            || fileExists(named: "Cargo.toml", in: directory) {
            return .rust
        }

        if RunCommandAdapter.isGoCommand(runCommand)
            || fileExists(named: "go.mod", in: directory) {
            return .go
        }

        return RunCommandAdapter.detectedFramework(for: runCommand)
    }

    private static func loadPackageJSON(at directory: URL) -> [String: Any]? {
        let url = directory.appendingPathComponent("package.json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    private static func dependencyNames(in packageJSON: [String: Any]?) -> Set<String> {
        guard let packageJSON else { return [] }
        let dependencyKeys = (packageJSON["dependencies"] as? [String: Any])?.keys.map { String($0) } ?? []
        let devDependencyKeys = (packageJSON["devDependencies"] as? [String: Any])?.keys.map { String($0) } ?? []
        return Set(dependencyKeys + devDependencyKeys)
    }

    private static func fileExists(named name: String, in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path)
    }

    private static func hasNextConfig(in directory: URL) -> Bool {
        hasConfig(matching: "next.config", in: directory)
    }

    private static func hasConfig(matching prefix: String, in directory: URL) -> Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return false
        }
        return contents.contains { $0.hasPrefix(prefix) }
    }

    private static func composerRequiresLaravel(in directory: URL) -> Bool {
        let composerURL = directory.appendingPathComponent("composer.json")
        guard let data = try? Data(contentsOf: composerURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        let requirements = (json["require"] as? [String: Any])?.keys.map { String($0) } ?? []
        return requirements.contains("laravel/framework")
    }
}

extension Project {
    var detectedType: ProjectFramework {
        ProjectTypeDetector.detect(directoryPath: directoryPath, runCommand: runCommand)
    }
}
