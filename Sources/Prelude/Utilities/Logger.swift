import Foundation

public enum Logger {
    public enum Level {
        case info
        case warning
        case debug
        case error
    }

    public static nonisolated(unsafe) var capture: (@Sendable (String, Level) -> Void)? = nil

    private static func sendLog(_ message: String, level: Level) {
        print(message)
        // Local Build environment setting is not enabled when distributing archive
        if ProcessInfo.processInfo.environment["LOCAL_BUILD"] == nil, let capture {
            capture(message, level)
        }
    }

    public static func log(_ message: String) {
        sendLog("[Log]: \(message)", level: .info)
    }

    public static func verbose(_ message: String) {
        sendLog("[Verbose]: \(message)", level: .info)
    }

    public static func info(_ message: String) {
        sendLog("[Info]: \(message)", level: .info)
    }

    public static func warn(_ message: String) {
        sendLog("[Warn]: \(message)", level: .warning)
    }

    public static func debug(_ message: String) {
        sendLog("[Debug]: \(message)", level: .debug)
    }

    public static func error(_ message: String) {
        sendLog("[Error]: \(message)", level: .error)
    }

    public static func error(_ error: any Error, withMessage message: String) {
        sendLog(
            "[Error] \(message) \(error.localizedDescription): \(String(describing: error))",
            level: .error
        )
    }
}
