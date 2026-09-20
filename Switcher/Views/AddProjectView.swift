import AppKit
import SwiftUI

struct AddProjectView: View {
    @Environment(ProjectStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existingProject: Project?

    @State private var name = ""
    @State private var slug = ""
    @State private var slugWasEdited = false
    @State private var directoryPath = ""
    @State private var runCommand = "npm run dev"
    @State private var framework: ProjectFramework = .auto
    @State private var appPortText = ""
    @State private var iconName = IconCatalog.defaultIcon
    @State private var iconColorHex = IconCatalog.defaultColorHex
    @State private var startImmediately = true
    @State private var validationMessage: String?
    @State private var portValidationMessage: String?

    init(existingProject: Project? = nil) {
        self.existingProject = existingProject
    }

    private var isEditing: Bool { existingProject != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            syncSlugFromName(newValue)
                        }

                    HStack {
                        TextField("Slug", text: slugBinding)
                        Text(".localhost")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        TextField("Directory", text: $directoryPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Choose…") {
                            chooseDirectory()
                        }
                    }
                }

                Section("Server") {
                    Picker("Framework", selection: $framework) {
                        ForEach(ProjectFramework.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .onChange(of: framework) { _, newValue in
                        if runCommand == "npm run dev" || runCommand == "mint dev" {
                            runCommand = newValue.defaultCommand
                        }
                    }

                    TextField("Run command", text: $runCommand, prompt: Text("npm run dev"))
                        .font(.body.monospaced())

                    if detectedFramework == .mintlify {
                        Text("Mintlify ignores PORT from portless. Switcher injects --port and --no-open so the proxy can route correctly.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        TextField("App port", text: $appPortText)
                            .font(.body.monospacedDigit())
                            .onChange(of: appPortText) { _, _ in
                                validatePortField()
                            }

                        Button("Suggest") {
                            suggestPort()
                        }
                    }

                    if let portValidationMessage {
                        Text(portValidationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let appPort {
                        Text("Port \(appPort) is available.")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    LabeledContent("Portless command") {
                        Text(previewCommand)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    LabeledContent("URL") {
                        Text(previewURL)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    if !isEditing {
                        Toggle("Start immediately", isOn: $startImmediately)
                    }
                }

                Section("Appearance") {
                    IconPickerView(selectedIcon: $iconName, selectedColorHex: $iconColorHex)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Project" : "Add Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .frame(minWidth: 520, minHeight: 640)
            .onAppear {
                loadExisting()
                if appPortText.isEmpty {
                    suggestPort()
                }
            }
        }
    }

    private var slugBinding: Binding<String> {
        Binding(
            get: { slug },
            set: { newValue in
                slugWasEdited = true
                slug = newValue
            }
        )
    }

    private func syncSlugFromName(_ newName: String) {
        guard !slugWasEdited else { return }
        slug = Slugifier.slug(from: newName)
    }

    private var appPort: Int? {
        Int(appPortText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var detectedFramework: ProjectFramework {
        framework == .auto ? RunCommandAdapter.detectedFramework(for: runCommand) : framework
    }

    private var previewCommand: String {
        let slugValue = slug.isEmpty ? "slug" : slug
        let portValue = appPort ?? 0
        if portValue > 0 {
            return PortlessConfiguration.portlessCommand(
                slug: slugValue,
                appPort: portValue,
                runCommand: runCommand
            )
        }
        return "portless \(slugValue) --app-port <port> \(runCommand)"
    }

    private var previewURL: String {
        let slugValue = slug.isEmpty ? "slug" : slug
        return PortlessConfiguration.localhostURL(slug: slugValue).absoluteString
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !directoryPath.isEmpty
            && !runCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && FileManager.default.fileExists(atPath: directoryPath)
            && appPort != nil
            && portValidationMessage == nil
    }

    private func loadExisting() {
        guard let existingProject else { return }
        name = existingProject.name
        slug = existingProject.slug
        slugWasEdited = true
        directoryPath = existingProject.directoryPath
        runCommand = existingProject.runCommand
        appPortText = String(existingProject.appPort)
        iconName = existingProject.iconName
        iconColorHex = existingProject.iconColorHex
        startImmediately = false
        validatePortField()
    }

    private func suggestPort() {
        if let port = store.suggestAppPort(excludingProjectID: existingProject?.id) {
            appPortText = String(port)
            validatePortField()
        } else {
            portValidationMessage = "No available ports in the \(PortlessConfiguration.appPortRange.lowerBound)–\(PortlessConfiguration.appPortRange.upperBound) range."
        }
    }

    private func validatePortField() {
        guard let port = appPort else {
            portValidationMessage = "Enter a valid port number."
            return
        }

        let result = store.validateAppPort(port, excludingProjectID: existingProject?.id)
        portValidationMessage = result.message
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            directoryPath = url.path
            if name.isEmpty {
                let folderName = url.lastPathComponent
                name = folderName
                slugWasEdited = false
                syncSlugFromName(folderName)
            }
        }
    }

    private func save() {
        validationMessage = nil

        let trimmedSlug = Slugifier.slug(from: slug)
        if trimmedSlug != slug {
            slug = trimmedSlug
        }

        if store.projects.contains(where: { $0.slug == trimmedSlug && $0.id != existingProject?.id }) {
            validationMessage = "Another project already uses the slug \"\(trimmedSlug)\"."
            return
        }

        validatePortField()
        guard let port = appPort, portValidationMessage == nil else {
            validationMessage = portValidationMessage ?? "Enter a valid app port."
            return
        }

        if let existingProject {
            let updated = Project(
                id: existingProject.id,
                name: name,
                slug: trimmedSlug,
                directoryPath: directoryPath,
                runCommand: runCommand,
                appPort: port,
                iconName: iconName,
                iconColorHex: iconColorHex,
                createdAt: existingProject.createdAt
            )
            store.updateProject(updated)
        } else {
            store.addProject(
                name: name,
                slug: trimmedSlug,
                directoryPath: directoryPath,
                runCommand: runCommand,
                appPort: port,
                iconName: iconName,
                iconColorHex: iconColorHex,
                startImmediately: startImmediately
            )
        }

        dismiss()
    }
}
