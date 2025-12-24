//
//  AISecureLogger.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//
//  Usage:
//    // Enable debug logging
//    AISecureLogLevel.callerDesiredLogLevel = .debug
//
//    // Enable timestamps for performance measurement
//    AISecureLogLevel.showTimestamps = true
//
//  Example output with timestamps:
//    [14:32:45.123] 🔄 Authenticating device with backend
//    [14:32:45.456] ✅ Device authenticated, JWT expires at 1766532884197
//    [14:32:45.489] ➡️ Request to /v1/chat/completions
//

import OSLog

public enum AISecureLogLevel: Int, Sendable {
    case debug
    case info
    case warning
    case error
    case critical

    func isAtOrAboveThresholdLevel(_ threshold: AISecureLogLevel) -> Bool {
        return self.rawValue >= threshold.rawValue
    }

    nonisolated(unsafe) static var _callerDesiredLogLevel = AISecureLogLevel.warning
    static var callerDesiredLogLevel: AISecureLogLevel {
        get {
            ProtectedPropertyQueue.logLevel.sync { self._callerDesiredLogLevel }
        }
        set {
            ProtectedPropertyQueue.logLevel.async(flags: .barrier) { self._callerDesiredLogLevel = newValue }
        }
    }

    nonisolated(unsafe) static var _showTimestamps = false
    public static var showTimestamps: Bool {
        get {
            ProtectedPropertyQueue.logLevel.sync { self._showTimestamps }
        }
        set {
            ProtectedPropertyQueue.logLevel.async(flags: .barrier) { self._showTimestamps = newValue }
        }
    }
}

internal let aisecureLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
    category: "AISecure"
)

// Timestamp formatter for high-precision logging
private let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()

// Custom logger wrapper that adds timestamps when enabled
internal struct AISecureTimestampLogger {
    private let logger: Logger
    private let logLevel: AISecureLogLevel

    init(logger: Logger, logLevel: AISecureLogLevel) {
        self.logger = logger
        self.logLevel = logLevel
    }

    func debug(_ message: String) {
        log(message, level: .debug)
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func warning(_ message: String) {
        log(message, level: .warning)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }

    func critical(_ message: String) {
        log(message, level: .critical)
    }

    private func log(_ message: String, level: AISecureLogLevel) {
        let finalMessage: String
        if AISecureLogLevel.showTimestamps {
            let now = Date()
            let timestamp = timestampFormatter.string(from: now)
            let milliseconds = Int(now.timeIntervalSince1970 * 1000) % 1000
            finalMessage = "[\(timestamp).\(String(format: "%03d", milliseconds))] \(message)"
        } else {
            finalMessage = message
        }

        switch level {
        case .debug:
            logger.debug("\(finalMessage)")
        case .info:
            logger.info("\(finalMessage)")
        case .warning:
            logger.warning("\(finalMessage)")
        case .error:
            logger.error("\(finalMessage)")
        case .critical:
            logger.critical("\(finalMessage)")
        }
    }
}

@inline(__always)
internal func logIf(_ logLevel: AISecureLogLevel) -> AISecureTimestampLogger? {
    return logLevel.isAtOrAboveThresholdLevel(AISecureLogLevel.callerDesiredLogLevel)
        ? AISecureTimestampLogger(logger: aisecureLogger, logLevel: logLevel)
        : nil
}
