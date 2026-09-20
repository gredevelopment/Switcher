import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []
    private(set) var settings: SwitcherSettings = .default
    private var sessions: [UUID: RunningProjectSession] = [:]

    private let documentStore = ICloudDocumentStore()

    init() {
        loadFromLocal()
        documentStore.startObservingChanges { [weak self] filename in
            self?.handleRemoteDocumentChange(filename: filename)
        }
        Task {
            await documentStore.synchronizeWithICloud()
            reloadFromLocal()
        }
    }

    func session(for projectID: UUID) -> RunningProjectSession {
        if let existing = sessions[projectID] {
            return existing
        }
        let session = RunningProjectSession(projectID: projectID)
        sessions[projectID] = session
        return session
    }

    func runState(for project: Project) -> ProjectRunState {
        session(for: project.id).state
    }

    func logs(for project: Project) -> [LogLine] {
        session(for: project.id).logs
    }

    func reservedPorts(excludingProjectID: UUID? = nil) -> Set<Int> {
        Set(
            projects
                .filter { $0.id != excludingProjectID && $0.appPort > 0 }
                .map(\.appPort)
        )
    }

    func suggestAppPort(excludingProjectID: UUID? = nil) -> Int? {
        PortMonitor.nextAvailablePort(excluding: reservedPorts(excludingProjectID: excludingProjectID))
    }

    func validateAppPort(_ port: Int, excludingProjectID: UUID? = nil) -> PortValidationResult {
        PortMonitor.validatePort(port, excludingProjectID: excludingProjectID, projects: projects)
    }

    func addProject(
        name: String,
        slug: String,
        directoryPath: String,
        runCommand: String,
        appPort: Int,
        iconName: String,
        iconColorHex: String,
        startImmediately: Bool = false
    ) {
        let project = Project(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
            directoryPath: directoryPath,
            runCommand: runCommand.trimmingCharacters(in: .whitespacesAndNewlines),
            appPort: appPort,
            iconName: iconName,
            iconColorHex: iconColorHex
        )
        projects.insert(project, at: 0)
        save()

        if startImmediately {
            start(project)
        }
    }

    func updateProject(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index] = project
        save()
    }

    func deleteProject(_ project: Project) {
        stop(project)
        projects.removeAll { $0.id == project.id }
        sessions.removeValue(forKey: project.id)
        save()
    }

    func start(_ project: Project) {
        let session = session(for: project.id)
        guard !session.state.isActive else { return }

        do {
            try PortlessProxyManager.ensureRunning()
            try session.start(project: project)
        } catch {
            session.state = .crashed(exitCode: -1)
            session.appendSystemLog(error.localizedDescription)
        }
    }

    func stop(_ project: Project) {
        session(for: project.id).stop()
    }

    func stopAllAndWait() {
        for project in projects {
            session(for: project.id).stopAndWait()
        }
        PortlessProxyManager.stopIfStartedByApp()
    }

    func toggle(_ project: Project) {
        if runState(for: project).isActive {
            stop(project)
        } else {
            start(project)
        }
    }

    func openInBrowser(_ project: Project) {
        NSWorkspace.shared.open(project.localhostURL)
    }

    func moveProjects(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func deleteProjects(withIDs ids: Set<UUID>) {
        let projectsToDelete = projects.filter { ids.contains($0.id) }
        for project in projectsToDelete {
            deleteProject(project)
        }
    }

    func startProjects(withIDs ids: Set<UUID>) {
        for project in projects where ids.contains(project.id) {
            start(project)
        }
    }

    func stopProjects(withIDs ids: Set<UUID>) {
        for project in projects where ids.contains(project.id) {
            stop(project)
        }
    }

    func updateSettings(_ newSettings: SwitcherSettings) {
        settings = newSettings
        saveSettings()
    }

    private func loadFromLocal() {
        if let loadedProjects = documentStore.loadLocal([Project].self, from: AppConstants.projectsDocumentName) {
            projects = loadedProjects
            migrateMissingPorts()
        }

        settings = documentStore.loadLocal(SwitcherSettings.self, from: AppConstants.settingsDocumentName) ?? .default
        saveSettingsIfNeeded()
    }

    private func reloadFromLocal() {
        loadFromLocal()
    }

    private func handleRemoteDocumentChange(filename: String) {
        switch filename {
        case AppConstants.projectsDocumentName:
            guard let loadedProjects = documentStore.loadLocal([Project].self, from: filename) else { return }
            projects = loadedProjects
            migrateMissingPorts()
            NotificationCenter.default.post(name: .iCloudStoreChanged, object: nil)
        case AppConstants.settingsDocumentName:
            settings = documentStore.loadLocal(SwitcherSettings.self, from: filename) ?? .default
            NotificationCenter.default.post(name: .iCloudStoreChanged, object: nil)
        default:
            break
        }
    }

    private func migrateMissingPorts() {
        var changed = false

        for index in projects.indices where projects[index].appPort == 0 {
            if let port = suggestAppPort(excludingProjectID: projects[index].id) {
                projects[index].appPort = port
                changed = true
            }
        }

        if changed {
            save()
        }
    }

    private func save() {
        documentStore.save(projects, to: AppConstants.projectsDocumentName)
    }

    private func saveSettings() {
        documentStore.save(settings, to: AppConstants.settingsDocumentName)
    }

    private func saveSettingsIfNeeded() {
        guard documentStore.loadLocal(SwitcherSettings.self, from: AppConstants.settingsDocumentName) == nil else {
            return
        }
        saveSettings()
    }
}
