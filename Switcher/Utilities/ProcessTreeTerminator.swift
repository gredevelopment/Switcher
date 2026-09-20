import Darwin
import Foundation

enum ProcessTreeTerminator {
    static func terminateTree(rootPID: pid_t, timeout: TimeInterval = 3) {
        guard rootPID > 0 else { return }

        let pids = allDescendantPIDs(of: rootPID)
        guard !pids.isEmpty else { return }

        for pid in pids {
            kill(pid, SIGTERM)
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !pids.contains(where: isRunning) {
                return
            }
            usleep(50_000)
        }

        for pid in pids where isRunning(pid) {
            kill(pid, SIGKILL)
        }
    }

    private static func allDescendantPIDs(of rootPID: pid_t) -> [pid_t] {
        var result = [pid_t]()
        var queue = [rootPID]

        while let pid = queue.popLast() {
            result.append(pid)
            queue.append(contentsOf: listChildPIDs(of: pid))
        }

        return result.reversed()
    }

    private static func listChildPIDs(of ppid: pid_t) -> [pid_t] {
        let capacity = 4_096
        var buffer = [pid_t](repeating: 0, count: capacity)
        let byteCount = capacity * MemoryLayout<pid_t>.size
        let size = proc_listchildpids(ppid, &buffer, Int32(byteCount))
        guard size > 0 else { return [] }

        let count = Int(size) / MemoryLayout<pid_t>.size
        return Array(buffer.prefix(count))
    }

    private static func isRunning(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }
}
