import Foundation
import Darwin

enum PortMonitor {
    static func isPortAvailable(_ port: Int) -> Bool {
        guard port > 0, port <= 65535 else { return false }

        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { return false }
        defer { close(socketFD) }

        var reuseAddr: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                bind(socketFD, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        return bindResult == 0
    }

    static func isPortListening(_ port: Int) -> Bool {
        isPortListening(host: "127.0.0.1", port: port)
            || isPortListening(host: "::1", port: port)
    }

    private static func isPortListening(host: String, port: Int) -> Bool {
        guard port > 0, port <= 65535 else { return false }

        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var info: UnsafeMutablePointer<addrinfo>?
        let portString = String(port)
        let status = getaddrinfo(host, portString, &hints, &info)
        guard status == 0, let info else { return false }
        defer { freeaddrinfo(info) }

        let socketFD = socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
        guard socketFD >= 0 else { return false }
        defer { close(socketFD) }

        let connected = connect(socketFD, info.pointee.ai_addr, info.pointee.ai_addrlen) == 0
        return connected
    }

    static func nextAvailablePort(
        excluding reservedPorts: Set<Int> = [],
        preferred: Int? = nil
    ) -> Int? {
        if let preferred, !reservedPorts.contains(preferred), isPortAvailable(preferred) {
            return preferred
        }

        for port in PortlessConfiguration.appPortRange {
            if reservedPorts.contains(port) { continue }
            if isPortAvailable(port) { return port }
        }

        return nil
    }

    static func validatePort(
        _ port: Int,
        excludingProjectID: UUID? = nil,
        projects: [Project]
    ) -> PortValidationResult {
        guard PortlessConfiguration.appPortRange.contains(port) else {
            return .invalid("Port must be between \(PortlessConfiguration.appPortRange.lowerBound) and \(PortlessConfiguration.appPortRange.upperBound).")
        }

        let reservedByOther = projects.contains { project in
            project.id != excludingProjectID && project.appPort == port
        }
        if reservedByOther {
            return .invalid("Another Switcher project already uses port \(port).")
        }

        if !isPortAvailable(port) {
            let keepsOwnPort = projects.contains { project in
                project.id == excludingProjectID && project.appPort == port
            }
            if !keepsOwnPort {
                return .invalid("Port \(port) is already in use on this machine.")
            }
        }

        return .valid
    }
}

enum PortValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}
