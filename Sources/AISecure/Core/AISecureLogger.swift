//
//  AISecureLogger.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
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
}

internal let aisecureLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "UnknownApp",
    category: "AISecure"
)

@inline(__always)
internal func logIf(_ logLevel: AISecureLogLevel) -> Logger? {
    return logLevel.isAtOrAboveThresholdLevel(AISecureLogLevel.callerDesiredLogLevel) ? aisecureLogger : nil
}
