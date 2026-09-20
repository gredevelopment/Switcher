import AppKit

@MainActor
final class SwitcherAppDelegate: NSObject, NSApplicationDelegate {
    weak var projectStore: ProjectStore?
    private var isStoppingForQuit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isStoppingForQuit {
            return .terminateNow
        }

        isStoppingForQuit = true
        projectStore?.stopAllAndWait()

        // macOS 27 tracks exec'd child processes separately. Give the system a
        // moment to observe that all background work has ended before exiting.
        DispatchQueue.main.async {
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func requestQuit() {
        NSApp.terminate(nil)
    }
}
