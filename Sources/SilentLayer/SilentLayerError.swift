//
//  SilentLayerError.swift
//  SilentLayer
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public enum SilentLayerErrorCode: String, Sendable {
    // Authentication errors (401)
    case sessionExpired = "SESSION_EXPIRED"
    case deviceMismatch = "DEVICE_MISMATCH"
    case invalidSignature = "INVALID_SIGNATURE"
    
    // Rate limit errors (429)
    case planQuotaExceeded = "PLAN_QUOTA_EXCEEDED"
    case userRateLimitExceeded = "USER_RATE_LIMIT_EXCEEDED"
    
    // Unknown
    case unknown = "UNKNOWN"
    
    /// Whether this error can be resolved by refreshing credentials
    public var isRecoverable: Bool {
        switch self {
        case .sessionExpired:
            return true  // Can retry with fresh JWT
        case .deviceMismatch, .invalidSignature:
            return false // Security error, don't retry
        case .planQuotaExceeded, .userRateLimitExceeded:
            return false // Must wait for limit reset
        case .unknown:
            return false
        }
    }
    
    /// Human-readable description
    public var localizedDescription: String {
        switch self {
        case .sessionExpired:
            return "Your session has expired. Please try again."
        case .deviceMismatch:
            return "Security error: Request origin does not match session."
        case .invalidSignature:
            return "Security verification failed."
        case .planQuotaExceeded:
            return "This service has reached its monthly capacity."
        case .userRateLimitExceeded:
            return "You've reached your request limit. Please wait before trying again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Error Body

/// Structured error body parsed from HTTP error responses
public struct HTTPErrorBody: Sendable, CustomStringConvertible {
    /// Error code from backend (e.g., "SESSION_EXPIRED")
    public let code: SilentLayerErrorCode
    
    /// Raw code string (for unknown codes)
    public let rawCode: String?
    
    /// Error message from backend
    public let message: String?
    
    /// HTTP status code
    public let statusCode: Int?
    
    /// Seconds until rate limit resets (for 429 errors)
    public let retryAfter: Int?
    
    /// Usage information (for rate limit errors)
    public let usage: UsageInfo?
    
    /// Raw response string (fallback)
    public let raw: String
    
    public var description: String {
        if let message = message {
            return message
        }
        return raw
    }
    
    /// Usage information for rate limit errors
    public struct UsageInfo: Sendable {
        public let used: Int
        public let limit: Int
        public let period: String?
        public let tier: String?
    }
    
    /// Initialize from raw response data
    public init(from data: Data) {
        let rawString = String(data: data, encoding: .utf8) ?? "Unknown error"
        self.raw = rawString
        
        // Try to parse JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Parse code
            let codeString = json["code"] as? String
            self.rawCode = codeString
            self.code = SilentLayerErrorCode(rawValue: codeString ?? "") ?? .unknown
            
            // Parse message - Lambda sends it in "error" field
            self.message = json["error"] as? String ?? json["message"] as? String
            
            // Parse status code
            self.statusCode = json["statusCode"] as? Int
            
            // Parse retry after (root level, not nested)
            self.retryAfter = json["retryAfter"] as? Int
            
            // Parse usage
            if let usageDict = json["usage"] as? [String: Any] {
                self.usage = UsageInfo(
                    used: usageDict["used"] as? Int ?? 0,
                    limit: usageDict["limit"] as? Int ?? 0,
                    period: usageDict["period"] as? String,
                    tier: usageDict["tier"] as? String
                )
            } else {
                self.usage = nil
            }
        } else {
            self.code = .unknown
            self.rawCode = nil
            self.message = rawString
            self.statusCode = nil
            self.retryAfter = nil
            self.usage = nil
        }
    }
    
    /// Initialize with a simple string message
    public init(message: String) {
        self.raw = message
        self.message = message
        self.code = .unknown
        self.rawCode = nil
        self.statusCode = nil
        self.retryAfter = nil
        self.usage = nil
    }
}

// MARK: - Rate Limit Info

/// Information about rate limiting from backend
public struct SilentLayerRateLimitInfo: Sendable {
    /// Seconds until the rate limit resets
    public let retryAfter: Int
    
    /// Current usage count
    public let used: Int?
    
    /// Maximum allowed requests
    public let limit: Int?
    
    /// Time period (hourly, daily, monthly)
    public let period: String?
    
    /// Plan tier (for plan quota errors)
    public let tier: String?
    
    /// Whether this is a device-level limit (vs account-level)
    public let isDeviceLimit: Bool
    
    init(from body: HTTPErrorBody, isDeviceLimit: Bool) {
        self.retryAfter = body.retryAfter ?? 60
        self.used = body.usage?.used
        self.limit = body.usage?.limit
        self.period = body.usage?.period
        self.tier = body.usage?.tier
        self.isDeviceLimit = isDeviceLimit
    }
    
    init(retryAfter: Int) {
        self.retryAfter = retryAfter
        self.used = nil
        self.limit = nil
        self.period = nil
        self.tier = nil
        self.isDeviceLimit = false
    }
}

// MARK: - Main Error Type

public enum SilentLayerError: Error, LocalizedError, Sendable {
    // MARK: - Authentication Errors
    
    /// Session has expired, need to re-authenticate
    case sessionExpired
    
    /// Device fingerprint doesn't match the session
    case deviceMismatch
    
    /// Request signature verification failed
    case invalidSignature
    
    // MARK: - Rate Limit Errors
    
    /// Account/plan monthly quota exceeded
    case planQuotaExceeded(SilentLayerRateLimitInfo)
    
    /// Device-level rate limit exceeded
    case userRateLimited(SilentLayerRateLimitInfo)
    
    /// Generic rate limit (legacy)
    case rateLimited(SilentLayerRateLimitInfo)
    
    // MARK: - Service Errors
    
    /// Service is temporarily unavailable
    case serviceUnavailable(retryAfter: Int, reason: String)
    
    /// HTTP error with status code and body
    case httpError(status: Int, body: HTTPErrorBody)
    
    // MARK: - Client Errors
    
    /// Invalid configuration
    case invalidConfiguration(String)
    
    /// Invalid response from server
    case invalidResponse
    
    /// Failed to decode response
    case decodingError(String)
    
    /// Network error
    case networkError(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .sessionExpired:
            return "Your session has expired. Please try again."
        case .deviceMismatch:
            return "Security error: This request cannot be completed from this device."
        case .invalidSignature:
            return "Security verification failed. Please try again."
        case .planQuotaExceeded(let info):
            return "Service capacity reached. Resets in \(formatDuration(info.retryAfter))."
        case .userRateLimited(let info):
            return "Rate limit reached. Please wait \(formatDuration(info.retryAfter))."
        case .rateLimited(let info):
            return "Too many requests. Please wait \(formatDuration(info.retryAfter))."
        case .serviceUnavailable(_, let reason):
            return "Service temporarily unavailable: \(reason)"
        case .httpError(let status, let body):
            return "HTTP \(status): \(body.message ?? body.raw)"
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
    
    // MARK: - Helper Properties
    
    /// Whether the request can be retried (possibly after waiting)
    public var isRetryable: Bool {
        switch self {
        case .sessionExpired:
            return true  // Retry with fresh credentials
        case .deviceMismatch, .invalidSignature:
            return false // Security errors, don't retry
        case .planQuotaExceeded, .userRateLimited, .rateLimited:
            return true  // Can retry after waiting
        case .serviceUnavailable:
            return true
        case .httpError(let status, _):
            return status >= 500 || status == 429
        case .networkError:
            return true
        case .invalidConfiguration, .invalidResponse, .decodingError:
            return false
        }
    }
    
    /// Seconds to wait before retrying (nil if not applicable)
    public var retryAfter: Int? {
        switch self {
        case .planQuotaExceeded(let info), .userRateLimited(let info), .rateLimited(let info):
            return info.retryAfter
        case .serviceUnavailable(let retryAfter, _):
            return retryAfter
        case .httpError(_, let body):
            return body.retryAfter
        default:
            return nil
        }
    }
    
    /// The error code if available
    public var code: SilentLayerErrorCode? {
        switch self {
        case .sessionExpired:
            return .sessionExpired
        case .deviceMismatch:
            return .deviceMismatch
        case .invalidSignature:
            return .invalidSignature
        case .planQuotaExceeded:
            return .planQuotaExceeded
        case .userRateLimited:
            return .userRateLimitExceeded
        case .httpError(_, let body):
            return body.code
        default:
            return nil
        }
    }
    
    /// Whether this error indicates credentials should be refreshed
    var shouldRefreshCredentials: Bool {
        switch self {
        case .sessionExpired:
            return true
        case .httpError(let status, let body):
            return status == 401 && body.code == .sessionExpired
        default:
            return false
        }
    }
    
    /// Whether this error should NOT trigger a retry (unrecoverable)
    var isUnrecoverable: Bool {
        switch self {
        case .deviceMismatch, .invalidSignature:
            return true
        case .httpError(_, let body):
            return body.code == .deviceMismatch || body.code == .invalidSignature
        default:
            return false
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create appropriate error from HTTP status and body
    static func from(status: Int, body: HTTPErrorBody) -> SilentLayerError {
        // Check for specific error codes first
        switch body.code {
        case .sessionExpired:
            return .sessionExpired
        case .deviceMismatch:
            return .deviceMismatch
        case .invalidSignature:
            return .invalidSignature
        case .planQuotaExceeded:
            return .planQuotaExceeded(SilentLayerRateLimitInfo(from: body, isDeviceLimit: false))
        case .userRateLimitExceeded:
            return .userRateLimited(SilentLayerRateLimitInfo(from: body, isDeviceLimit: true))
        case .unknown:
            break
        }
        
        // Fall back to status code based errors
        switch status {
        case 401:
            return .httpError(status: status, body: body)
        case 429:
            return .rateLimited(SilentLayerRateLimitInfo(from: body, isDeviceLimit: false))
        case 503:
            return .serviceUnavailable(
                retryAfter: body.retryAfter ?? 30,
                reason: body.message ?? "Service temporarily unavailable"
            )
        default:
            return .httpError(status: status, body: body)
        }
    }
}

// MARK: - Helpers

private func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 {
        return "\(seconds) seconds"
    } else if seconds < 3600 {
        let minutes = seconds / 60
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    } else if seconds < 86400 {
        let hours = seconds / 3600
        return "\(hours) hour\(hours == 1 ? "" : "s")"
    } else {
        let days = seconds / 86400
        return "\(days) day\(days == 1 ? "" : "s")"
    }
}
