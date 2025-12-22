//
//  AISecureError.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public enum AISecureError: Error, LocalizedError, @unchecked Sendable {
    case invalidResponse
    case httpError(status: Int, body: Any)
    case decodingError(Error)
    case providerNotConfigured(String)
    case invalidConfiguration(String)
    case sessionExpired
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let status, _):
            return "HTTP error: \(status)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .providerNotConfigured(let provider):
            return "Provider not configured: \(provider)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .sessionExpired:
            return "Session expired"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    public var debugInfo: Any? {
        switch self {
        case .httpError(_, let body):
            return body
        case .decodingError(let error):
            return error
        case .networkError(let error):
            return error
        default:
            return nil
        }
    }
}
