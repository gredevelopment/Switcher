import SwiftUI

@main
struct SwitcherApp: App {
    @NSApplicationDelegateAdaptor(SwitcherAppDelegate.self) private var appDelegate
    @State private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onAppear {
                    appDelegate.projectStore = store
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 450, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    NotificationCenter.default.post(name: .createProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
