import SwiftUI

struct ContentView: View {
    @Environment(ProjectStore.self) private var store
    @State private var showingAddProject = false
    @State private var projectToEdit: Project?
    @State private var isEditingList = false
    @State private var selectedProjectIDs = Set<UUID>()

    var body: some View {
        NavigationStack {
            Group {
                if store.projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Switcher")
            .toolbar {
                if isEditingList {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if !selectedProjectIDs.isEmpty {
                            Menu {
                                Button("Start Selected") {
                                    store.startProjects(withIDs: selectedProjectIDs)
                                }
                                Button("Stop Selected") {
                                    store.stopProjects(withIDs: selectedProjectIDs)
                                }
                                Divider()
                                Button("Delete Selected", role: .destructive) {
                                    store.deleteProjects(withIDs: selectedProjectIDs)
                                    selectedProjectIDs.removeAll()
                                }
                            } label: {
                                Label("Actions", systemImage: "ellipsis.circle")
                            }
                            .help("Bulk actions for selected projects")
                        }

                        Button {
                            finishEditing()
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .help("Finish editing")
                    }
                } else {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            showingAddProject = true
                        } label: {
                            Label("Add Project", systemImage: "plus")
                        }
                        .help("Add a new project")

                        Button {
                            isEditingList = true
                        } label: {
                            Label("Edit List", systemImage: "square.and.pencil")
                        }
                        .help("Select, reorder, or bulk edit projects")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
            .sheet(item: $projectToEdit) { project in
                AddProjectView(existingProject: project)
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .background {
            AppGlassBackground()
                .ignoresSafeArea()
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
        .task {
            try? PortlessProxyManager.ensureRunning()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Projects", systemImage: "folder.badge.plus")
        } description: {
            Text("Add a project directory and run command to get started with portless.")
        } actions: {
            Button("Add Project") {
                showingAddProject = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var projectList: some View {
        List {
            ForEach(store.projects) { project in
                VStack(spacing: 0) {
                    ProjectRowView(
                        project: project,
                        isEditingList: isEditingList,
                        isSelected: selectedProjectIDs.contains(project.id),
                        onToggleSelection: {
                            toggleSelection(for: project.id)
                        },
                        onEdit: {
                            projectToEdit = project
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if project.id != store.projects.last?.id {
                        FullWidthRowSeparator()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onMove { source, destination in
                store.moveProjects(from: source, to: destination)
            }
            .moveDisabled(!isEditingList)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func toggleSelection(for projectID: UUID) {
        if selectedProjectIDs.contains(projectID) {
            selectedProjectIDs.remove(projectID)
        } else {
            selectedProjectIDs.insert(projectID)
        }
    }

    private func finishEditing() {
        isEditingList = false
        selectedProjectIDs.removeAll()
    }
}
