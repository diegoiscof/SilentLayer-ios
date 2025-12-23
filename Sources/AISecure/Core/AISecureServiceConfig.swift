//
//  AISecureServiceConfig.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public struct AISecureServiceConfig: Sendable {
    public let provider: String
    public let serviceURL: String
    public let partialKey: String

    /// Creates a service configuration
    ///
    /// - Parameters:
    ///   - provider: The AI provider (e.g., "openai", "anthropic", "google")
    ///   - serviceURL: The full service URL
    ///   - partialKey: The partial API key from the backend
    ///
    /// - Throws: AISecureError if the configuration is invalid
    public init(
        provider: String,
        serviceURL: String,
        partialKey: String
    ) throws {
        guard !provider.isEmpty else {
            throw AISecureError.invalidConfiguration("Provider cannot be empty")
        }
        guard !serviceURL.isEmpty else {
            throw AISecureError.invalidConfiguration("Service URL cannot be empty")
        }
        guard !partialKey.isEmpty else {
            throw AISecureError.invalidConfiguration("Partial key cannot be empty")
        }

        self.provider = provider
        self.serviceURL = serviceURL
        self.partialKey = partialKey
    }
}
