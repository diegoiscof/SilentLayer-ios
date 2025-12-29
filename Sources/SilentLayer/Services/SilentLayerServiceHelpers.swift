//
//  SilentLayerServiceHelpers.swift
//  SilentLayer
//
//  Created by Diego Francisco Oruna Cabrera on 25/12/25.
//

import Foundation

/// Tracks retry attempts for credential refresh
private enum RetryState {
    case initial
    case retriedWithFreshCredentials
}

@SilentLayerActor
internal struct SilentLayerServiceHelpers {
    
    // MARK: - Retry State
    
    private enum RetryState {
        case initial
        case retriedWithFreshCredentials
        
        @SilentLayerActor mutating func handleAuthFailure(
            authenticator: SilentLayerDeviceAuthenticator?,
            errorCode: String? = nil
        ) -> Bool {
            // Don't retry for certain error types
            if let code = errorCode {
                switch code {
                case "DEVICE_MISMATCH", "INVALID_SIGNATURE":
                    logIf(.error)?.error("❌ Auth error (\(code)) - not recoverable")
                    return false
                default:
                    break
                }
            }
            
            switch self {
            case .initial:
                guard let authenticator = authenticator else {
                    logIf(.error)?.error("❌ No authenticator for credential refresh")
                    return false
                }
                
                logIf(.info)?.info("⚠️ Auth failed (401), refreshing credentials...")
                authenticator.invalidateCredentials()
                
                self = .retriedWithFreshCredentials
                return true
                
            case .retriedWithFreshCredentials:
                logIf(.error)?.error("❌ Auth failed after refresh - giving up")
                return false
            }
        }
        
        var shouldForceRefresh: Bool {
            self == .retriedWithFreshCredentials
        }
    }
    
    // MARK: - Public API
    
    /// Execute a request with automatic credential refresh on 401
    ///
    /// Flow:
    /// 1. Get credentials (cached if valid)
    /// 2. Execute request
    /// 3. On 401 with recoverable code → refresh credentials and retry once
    /// 4. On unrecoverable error → throw immediately (no retry)
    ///
    /// - Parameters:
    ///   - deviceAuthenticator: The authenticator for credential management
    ///   - configuration: Service configuration
    ///   - operation: The async operation to execute with credentials
    /// - Returns: The operation result (Data, URLResponse)
    @discardableResult
    public static func executeWithRetry(
        deviceAuthenticator: SilentLayerDeviceAuthenticator,
        configuration: SilentLayerConfiguration,
        operation: @Sendable (_ service: SilentLayerServiceConfig, _ session: SilentLayerSession) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var state = RetryState.initial
        
        while true {
            // Get credentials (force refresh if retrying)
            let forceRefresh = state == .retriedWithFreshCredentials
            let credentials: SilentLayerCredentials
            
            do {
                credentials = try await deviceAuthenticator.getCredentials(forceRefresh: forceRefresh)
            } catch {
                logIf(.error)?.error("❌ Failed to get credentials: \(error.localizedDescription)")
                throw error
            }
            
            do {
                // Execute the operation
                let result = try await operation(credentials.service, credentials.session)
                return result
                
            } catch let error as SilentLayerError {
                // Check if error is unrecoverable (don't retry)
                if error.isUnrecoverable {
                    logIf(.error)?.error("Unrecoverable error: \(error.localizedDescription)")
                    throw error
                }
                
                // Check if we should refresh credentials and retry
                if error.shouldRefreshCredentials && state == .initial {
                    logIf(.info)?.info("Session expired, refreshing credentials...")
                    await deviceAuthenticator.invalidateCredentials()
                    state = .retriedWithFreshCredentials
                    continue
                }
                
                // Not recoverable or already retried
                throw error
                
            } catch {
                // Handle non-AISecureError errors
                
                // Check for HTTP 401 in URLError or similar
                if let urlError = error as? URLError {
                    throw SilentLayerError.networkError(urlError.localizedDescription)
                }
                
                throw error
            }
        }
    }
    
    // MARK: - Response Validation
    
    /// Validate HTTP response and convert to appropriate error if needed
    ///
    /// - Parameters:
    ///   - response: The URLResponse to validate
    ///   - data: The response data (for error parsing)
    /// - Throws: AISecureError if response indicates an error
    public static func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SilentLayerError.invalidResponse
        }
        
        let statusCode = httpResponse.statusCode
        
        guard !(200...299).contains(statusCode) else {
            return
        }
        
        let errorBody = HTTPErrorBody(from: data)
        
        logIf(.error)?.error("❌ HTTP \(statusCode): \(errorBody.message ?? errorBody.raw)")
        
        throw SilentLayerError.from(status: statusCode, body: errorBody)
    }
    
    /// Parse error code from response data
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: The error code if found
    public static func parseErrorCode(from data: Data) -> SilentLayerErrorCode? {
        let body = HTTPErrorBody(from: data)
        return body.code != .unknown ? body.code : nil
    }
    
}
