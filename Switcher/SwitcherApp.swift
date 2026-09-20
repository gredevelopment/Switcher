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
        .defaultSize(width: 820, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
