import Foundation

/// Severity ordering for log messages.
public enum LogLevel: String, Comparable, Sendable {
    case debug
    case info
    case warning
    case error

    private var rank: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Destination for log output.
public protocol LogSink: AnyObject {
    func write(_ message: String, level: LogLevel)
}

/// Lightweight logging module.
public final class Logger {
    public static let shared = Logger()

    public var minimumLevel: LogLevel
    private var sinks: [LogSink] = []

    public init(minimumLevel: LogLevel = .info) {
        self.minimumLevel = minimumLevel
    }

    public func addSink(_ sink: LogSink) {
        sinks.append(sink)
    }

    public func log(_ message: String, level: LogLevel = .info) {
        guard level >= minimumLevel else { return }

        if sinks.isEmpty {
            print("[\(level.rawValue.uppercased())] \(message)")
        } else {
            sinks.forEach { $0.write(message, level: level) }
        }
    }
}
